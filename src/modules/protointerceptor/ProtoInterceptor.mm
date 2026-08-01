//
//  ProtoInterceptor.mm
//  ZoobaProto
//
//  ProtoBuf message interceptor using fishhook
//  Based on real routes from Zooba dump:
//  - Pitaya uses STRING routes (not numeric IDs!)
//  - Format: "metagame.playerHandler.authenticate"
//

#import "ProtoInterceptor.h"
#import "Config.h"
#import <fishhook/fishhook.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>

#define ZPLog(fmt, args...) \
    if (self.enabled && self.logToConsole) { \
        NSLog(@"[ZoobaProto/Proto] " fmt, ##args); \
    }

#pragma mark - ZPProtoMessageInfo

@implementation ZPProtoMessageInfo

- (instancetype)init {
    self = [super init];
    if (self) {
        _timestamp = [NSDate date];
        _direction = ZPProtoDirectionSend;
    }
    return self;
}

- (NSString *)description {
    NSString *dir = _direction == ZPProtoDirectionSend ? @"SEND" : @"RECV";
    return [NSString stringWithFormat:@"<ProtoMsg %@ route=%@ size=%lu>",
            dir, _route ?: _messageName ?: @"Unknown",
            (unsigned long)(_payload ? _payload.length : 0)];
}

@end

#pragma mark - ProtoInterceptor Private

@interface ProtoInterceptor ()
@property (nonatomic, strong) NSMutableArray<ZPProtoMessageInfo *> *mutableMessages;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *routeMappings;
@property (nonatomic, assign) uint32_t currentRequestId;
@end

#pragma mark - Original Function Pointers

static int (*original_send)(int sockfd, const void *buf, size_t len, int flags);
static int (*original_recv)(int sockfd, void *buf, size_t len, int flags);
static int (*original_write)(int fd, const void *buf, size_t count);
static int (*original_read)(int fd, void *buf, size_t count);

#pragma mark - Helper Functions

// Read varint from buffer
static uint32_t readVarint(const uint8_t **ptr, const uint8_t *end) {
    uint32_t result = 0;
    uint8_t shift = 0;
    while (*ptr < end) {
        uint8_t byte = *(*ptr)++;
        result |= (byte & 0x7F) << shift;
        if ((byte & 0x80) == 0) break;
        shift += 7;
    }
    return result;
}

// Read protobuf field from buffer
static NSDictionary *readProtobufField(const uint8_t **ptr, const uint8_t *end) {
    if (*ptr >= end) return nil;
    
    uint8_t tag = *(*ptr)++;
    uint32_t fieldNum = tag >> 3;
    uint32_t wireType = tag & 0x07;
    
    NSMutableDictionary *field = [NSMutableDictionary dictionary];
    field[@"fieldNumber"] = @(fieldNum);
    field[@"wireType"] = @(wireType);
    
    switch (wireType) {
        case 0: { // Varint
            uint32_t val = readVarint(ptr, end);
            field[@"value"] = @(val);
            field[@"type"] = @"varint";
            break;
        }
        case 1: { // 64-bit
            if (*ptr + 8 <= end) {
                uint64_t val = 0;
                for (int i = 0; i < 8; i++) {
                    val = (val << 8) | *(*ptr)++;
                }
                field[@"value"] = @(val);
                field[@"type"] = @"fixed64";
            }
            break;
        }
        case 2: { // Length-delimited
            uint32_t len = readVarint(ptr, end);
            if (*ptr + len <= end) {
                NSData *data = [NSData dataWithBytes:*ptr length:len];
                *ptr += len;
                
                // Try to decode as string
                NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                if (str) {
                    field[@"value"] = str;
                    field[@"type"] = @"string";
                } else {
                    // Hex for binary data
                    NSMutableString *hex = [NSMutableString string];
                    const uint8_t *hexBytes = data.bytes;
                    for (NSUInteger i = 0; i < MIN(data.length, 32); i++) {
                        [hex appendFormat:@"%02X", hexBytes[i]];
                    }
                    if (data.length > 32) [hex appendString:@"..."];
                    field[@"value"] = [NSString stringWithFormat:@"<%lu bytes: %@>", (unsigned long)data.length, hex];
                    field[@"type"] = @"bytes";
                }
            }
            break;
        }
        case 5: { // 32-bit
            if (*ptr + 4 <= end) {
                uint32_t val = 0;
                for (int i = 0; i < 4; i++) {
                    val = (val << 8) | *(*ptr)++;
                }
                field[@"value"] = @(val);
                field[@"type"] = @"fixed32";
            }
            break;
        }
        default:
            field[@"type"] = @"unknown";
            break;
    }
    
    return field;
}

// Parse protobuf data to dictionary
static NSDictionary *parseProtobuf(const uint8_t *data, NSUInteger length) {
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    const uint8_t *ptr = data;
    const uint8_t *end = data + length;
    
    while (ptr < end) {
        NSDictionary *field = readProtobufField(&ptr, end);
        if (field) {
            NSNumber *fieldNum = field[@"fieldNumber"];
            id value = field[@"value"];
            
            if (fieldNum && value) {
                NSString *key = [NSString stringWithFormat:@"field_%@", fieldNum];
                result[key] = value;
            }
        }
    }
    
    return result;
}

// Parse Pitaya packet
// Format: [type:1][route_len:varint][route:route_len bytes][request_id:varint][protobuf_data...]
static NSDictionary *parsePitayaPacket(const uint8_t *data, NSUInteger length, BOOL isSend) {
    if (length < 2) return nil;
    
    NSMutableDictionary *packet = [NSMutableDictionary dictionary];
    const uint8_t *ptr = data;
    const uint8_t *end = data + length;
    
    // Read message type
    uint8_t msgType = *ptr++;
    packet[@"msgType"] = @(msgType);
    
    NSArray *typeNames = @[@"Request", @"Response", @"Push", @"Error"];
    packet[@"msgTypeName"] = typeNames[msgType & 0x03];
    
    // Read route length (varint)
    uint32_t routeLen = readVarint(&ptr, end);
    if (routeLen == 0 || ptr + routeLen > end) return nil;
    
    // Read route string
    NSString *route = [[NSString alloc] initWithBytes:ptr length:routeLen encoding:NSUTF8StringEncoding];
    if (!route) return nil;
    ptr += routeLen;
    
    packet[@"route"] = route;
    
    // For responses, read request ID
    uint8_t type = msgType & 0x03;
    if (type == 1 || type == 2) { // Request or Response
        if (ptr < end) {
            uint32_t reqId = readVarint(&ptr, end);
            packet[@"requestId"] = @(reqId);
        }
    }
    
    // Remaining data is protobuf payload
    if (ptr < end) {
        NSUInteger payloadLen = end - ptr;
        NSData *payload = [NSData dataWithBytes:ptr length:payloadLen];
        packet[@"payload"] = payload;
        packet[@"payloadLength"] = @(payloadLen);
        
        // Try to parse protobuf
        NSDictionary *parsed = parseProtobuf(ptr, payloadLen);
        if (parsed.count > 0) {
            packet[@"parsedData"] = parsed;
        }
    }
    
    return packet;
}

#pragma mark - Hooked Functions

static int hooked_send(int sockfd, const void *buf, size_t len, int flags) {
    if (len < 4) {
        return original_send(sockfd, buf, len, flags);
    }
    
    ProtoInterceptor *interceptor = [ProtoInterceptor shared];
    if (!interceptor.enabled) {
        return original_send(sockfd, buf, len, flags);
    }
    
    @try {
        NSDictionary *packet = parsePitayaPacket(buf, len, YES);
        if (packet && packet[@"route"]) {
            ZPProtoMessageInfo *msg = [[ZPProtoMessageInfo alloc] init];
            msg.direction = ZPProtoDirectionSend;
            msg.route = packet[@"route"];
            msg.msgType = [packet[@"msgType"] unsignedCharValue];
            msg.requestId = [packet[@"requestId"] unsignedIntValue];
            msg.payload = packet[@"payload"];
            msg.rawData = [NSData dataWithBytes:buf length:len];
            msg.parsedData = packet[@"parsedData"];
            msg.messageName = [interceptor shortNameForRoute:msg.route];
            
            [interceptor captureMessage:msg];
        }
    } @catch (NSException *e) {
        // Silently ignore
    }
    
    return original_send(sockfd, buf, len, flags);
}

static int hooked_recv(int sockfd, void *buf, size_t len, int flags) {
    int result = original_recv(sockfd, buf, len, flags);
    
    if (result < 4) {
        return result;
    }
    
    ProtoInterceptor *interceptor = [ProtoInterceptor shared];
    if (!interceptor.enabled) {
        return result;
    }
    
    @try {
        NSDictionary *packet = parsePitayaPacket(buf, result, NO);
        if (packet && packet[@"route"]) {
            ZPProtoMessageInfo *msg = [[ZPProtoMessageInfo alloc] init];
            msg.direction = ZPProtoDirectionRecv;
            msg.route = packet[@"route"];
            msg.msgType = [packet[@"msgType"] unsignedCharValue];
            msg.requestId = [packet[@"requestId"] unsignedIntValue];
            msg.payload = packet[@"payload"];
            msg.rawData = [NSData dataWithBytes:buf length:result];
            msg.parsedData = packet[@"parsedData"];
            msg.messageName = [interceptor shortNameForRoute:msg.route];
            
            [interceptor captureMessage:msg];
        }
    } @catch (NSException *e) {
        // Silently ignore
    }
    
    return result;
}

static int hooked_write(int fd, const void *buf, size_t count) {
    if (count < 4) {
        return original_write(fd, buf, count);
    }
    
    ProtoInterceptor *interceptor = [ProtoInterceptor shared];
    if (!interceptor.enabled) {
        return original_write(fd, buf, count);
    }
    
    @try {
        NSDictionary *packet = parsePitayaPacket(buf, count, YES);
        if (packet && packet[@"route"]) {
            ZPProtoMessageInfo *msg = [[ZPProtoMessageInfo alloc] init];
            msg.direction = ZPProtoDirectionSend;
            msg.route = packet[@"route"];
            msg.msgType = [packet[@"msgType"] unsignedCharValue];
            msg.requestId = [packet[@"requestId"] unsignedIntValue];
            msg.payload = packet[@"payload"];
            msg.rawData = [NSData dataWithBytes:buf length:count];
            msg.parsedData = packet[@"parsedData"];
            msg.messageName = [interceptor shortNameForRoute:msg.route];
            
            [interceptor captureMessage:msg];
        }
    } @catch (NSException *e) {
        // Silently ignore
    }
    
    return original_write(fd, buf, count);
}

static int hooked_read(int fd, void *buf, size_t count) {
    int result = original_read(fd, buf, count);
    
    if (result < 4) {
        return result;
    }
    
    ProtoInterceptor *interceptor = [ProtoInterceptor shared];
    if (!interceptor.enabled) {
        return result;
    }
    
    @try {
        NSDictionary *packet = parsePitayaPacket(buf, result, NO);
        if (packet && packet[@"route"]) {
            ZPProtoMessageInfo *msg = [[ZPProtoMessageInfo alloc] init];
            msg.direction = ZPProtoDirectionRecv;
            msg.route = packet[@"route"];
            msg.msgType = [packet[@"msgType"] unsignedCharValue];
            msg.requestId = [packet[@"requestId"] unsignedIntValue];
            msg.payload = packet[@"payload"];
            msg.rawData = [NSData dataWithBytes:buf length:result];
            msg.parsedData = packet[@"parsedData"];
            msg.messageName = [interceptor shortNameForRoute:msg.route];
            
            [interceptor captureMessage:msg];
        }
    } @catch (NSException *e) {
        // Silently ignore
    }
    
    return result;
}

#pragma mark - ProtoInterceptor Implementation

@implementation ProtoInterceptor

+ (instancetype)shared {
    static ProtoInterceptor *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ProtoInterceptor alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _enabled = YES;
        _logToConsole = YES;
        _mutableMessages = [NSMutableArray array];
        _routeMappings = [NSMutableDictionary dictionary];
        _currentRequestId = 1;
        [self registerAllRoutes];
    }
    return self;
}

- (void)setup {
    ZPLog(@"ProtoInterceptor v2.1 - STRING ROUTES mode");
}

- (void)teardown {
    [self uninstallHooks];
    [_mutableMessages removeAllObjects];
}

#pragma mark - Route Registration

- (void)registerAllRoutes {
    [_routeMappings removeAllObjects];
    
    // AUTHENTICATION
    [self registerRoute:@"metagame.playerHandler.authenticate" withName:@"Authenticate"];
    [self registerRoute:@"metagame.playerHandler.changeName" withName:@"ChangeName"];
    [self registerRoute:@"metagame.playerHandler.timestamp" withName:@"Timestamp"];
    [self registerRoute:@"metagame.playerHandler.setPlayerOnline" withName:@"SetOnline"];
    
    // MATCHMAKING
    [self registerRoute:@"metagame.matchmakingHandler.findMatch" withName:@"FindMatch"];
    [self registerRoute:@"metagame.matchmakingHandler.findTeamMatch" withName:@"FindTeamMatch"];
    [self registerRoute:@"metagame.matchmakingHandler.getRoomsForPing" withName:@"GetRoomsForPing"];
    
    // MATCH (Gameplay)
    [self registerRoute:@"metagame.matchRemote.createMatch" withName:@"CreateMatch"];
    [self registerRoute:@"metagame.matchRemote.startMatch" withName:@"StartMatch"];
    [self registerRoute:@"metagame.matchRemote.finishMatch" withName:@"FinishMatch"];
    [self registerRoute:@"metagame.matchRemote.playerExitRoom" withName:@"PlayerExitRoom"];
    [self registerRoute:@"metagame.matchHandler.getMatchLog" withName:@"GetMatchLog"];
    
    // PLAYER
    [self registerRoute:@"metagame.playerHandler.changeChar" withName:@"ChangeChar"];
    [self registerRoute:@"metagame.playerHandler.getLoadouts" withName:@"GetLoadouts"];
    [self registerRoute:@"metagame.playerHandler.exchangeGems" withName:@"ExchangeGems"];
    [self registerRoute:@"metagame.playerHandler.getMetagamePlayerProfile" withName:@"GetPlayerProfile"];
    [self registerRoute:@"metagame.playerHandler.claimReward" withName:@"ClaimReward"];
    
    // ITEMS
    [self registerRoute:@"metagame.playerItemHandler.upgradeItemLevel" withName:@"UpgradeItemLevel"];
    [self registerRoute:@"metagame.playerItemHandler.swapLoadoutItems" withName:@"SwapLoadoutItems"];
    [self registerRoute:@"metagame.playerItemHandler.markNotNew" withName:@"MarkItemNotNew"];
    
    // CHARACTERS
    [self registerRoute:@"metagame.characterHandler.changeCharSkin" withName:@"ChangeSkin"];
    [self registerRoute:@"metagame.characterHandler.unlockCharacter" withName:@"UnlockCharacter"];
    [self registerRoute:@"metagame.characterHandler.upgradeCharacterLevel" withName:@"UpgradeCharLevel"];
    [self registerRoute:@"metagame.characterHandler.updateWeaponPoints" withName:@"UpdateWeaponPoints"];
    
    // CHEST
    [self registerRoute:@"metagame.chestHandler.startUnlocking" withName:@"StartUnlockChest"];
    [self registerRoute:@"metagame.chestHandler.enqueueChest" withName:@"QueueChest"];
    [self registerRoute:@"metagame.chestHandler.openMatchChest" withName:@"OpenMatchChest"];
    [self registerRoute:@"metagame.chestHandler.openFreeChest" withName:@"OpenFreeChest"];
    [self registerRoute:@"metagame.chestHandler.openShopChest" withName:@"OpenShopChest"];
    [self registerRoute:@"metagame.chestHandler.reRollMatchChest" withName:@"ReRollMatchChest"];
    [self registerRoute:@"metagame.chestHandler.reRollFreeChest" withName:@"ReRollFreeChest"];
    [self registerRoute:@"metagame.chestHandler.commitMatchChestChanges" withName:@"CommitMatchChest"];
    [self registerRoute:@"metagame.chestHandler.commitFreeChestChanges" withName:@"CommitFreeChest"];
    
    // SHOP/PURCHASE
    [self registerRoute:@"metagame.shopHandler.purchase" withName:@"Purchase"];
    [self registerRoute:@"metagame.shopHandler.registerPurchaseIntent" withName:@"RegisterPurchaseIntent"];
    [self registerRoute:@"metagame.shopHandler.registerConfirmedPurchaseIntent" withName:@"ConfirmPurchaseIntent"];
    [self registerRoute:@"metagame.offerHandler.purchaseOffer" withName:@"PurchaseOffer"];
    [self registerRoute:@"metagame.offerHandler.getOfferBundle" withName:@"GetOfferBundle"];
    [self registerRoute:@"metagame.pendingPurchasesHandler.getPendingPurchase" withName:@"GetPendingPurchase"];
    
    // CLAN
    [self registerRoute:@"metagame.clanHandler.getClan" withName:@"GetClan"];
    [self registerRoute:@"metagame.clanHandler.createClan" withName:@"CreateClan"];
    [self registerRoute:@"metagame.clanHandler.searchClans" withName:@"SearchClans"];
    [self registerRoute:@"metagame.clanHandler.applyForClan" withName:@"ApplyForClan"];
    [self registerRoute:@"metagame.clanHandler.inviteToClan" withName:@"InviteToClan"];
    [self registerRoute:@"metagame.clanHandler.approveApplication" withName:@"ApproveApplication"];
    [self registerRoute:@"metagame.clanHandler.removeMember" withName:@"RemoveMember"];
    [self registerRoute:@"metagame.clanHandler.updateClan" withName:@"UpdateClan"];
    
    // TEAM
    [self registerRoute:@"metagame.teamHandler.create" withName:@"CreateTeam"];
    [self registerRoute:@"metagame.teamHandler.join" withName:@"JoinTeam"];
    [self registerRoute:@"metagame.teamHandler.leave" withName:@"LeaveTeam"];
    [self registerRoute:@"metagame.teamHandler.inviteFriend" withName:@"InviteFriend"];
    [self registerRoute:@"metagame.teamHandler.acceptInvite" withName:@"AcceptInvite"];
    [self registerRoute:@"metagame.teamHandler.rejectInvite" withName:@"RejectInvite"];
    [self registerRoute:@"metagame.teamHandler.setStatusReady" withName:@"SetReady"];
    [self registerRoute:@"metagame.teamHandler.changeChar" withName:@"TeamChangeChar"];
    
    // RANKING
    [self registerRoute:@"metagame.rankingHandler.getTop" withName:@"GetTopRanking"];
    [self registerRoute:@"metagame.rankingHandler.getMembers" withName:@"GetMemberRanking"];
    
    // MISSION/EVENT
    [self registerRoute:@"metagame.missionHandler.getMissions" withName:@"GetMissions"];
    [self registerRoute:@"metagame.missionHandler.claim" withName:@"ClaimMission"];
    [self registerRoute:@"metagame.missionHandler.claimStreak" withName:@"ClaimStreak"];
    
    // ADS
    [self registerRoute:@"metagame.adsHandler.watchAd" withName:@"WatchAd"];
    [self registerRoute:@"metagame.adsHandler.multiplyRewardsUsingAd" withName:@"MultiplyRewards"];
    [self registerRoute:@"metagame.adsHandler.skipFreeCrateTimerUsingAd" withName:@"SkipTimer"];
    
    // BLAST (Mini-game)
    [self registerRoute:@"metagame.blastHandler.flipSymbol" withName:@"BlastFlipSymbol"];
    [self registerRoute:@"metagame.blastHandler.getBlasts" withName:@"GetBlasts"];
    [self registerRoute:@"metagame.blastHandler.enterBoard" withName:@"BlastEnterBoard"];
    [self registerRoute:@"metagame.blastHandler.exitBoard" withName:@"BlastExitBoard"];
    
    // TROPHY ROAD
    [self registerRoute:@"metagame.trophyRoadHandler.claimReward" withName:@"ClaimTrophyRoad"];
    [self registerRoute:@"metagame.trophyRoadHandler.claimSeasonalMasteryRoadReward" withName:@"ClaimMasteryReward"];
    
    // ACCOUNT
    [self registerRoute:@"metagame.accountHandler.linkAccount" withName:@"LinkAccount"];
    [self registerRoute:@"metagame.accountHandler.erasePlayerAccount" withName:@"EraseAccount"];
    [self registerRoute:@"metagame.playerHandler.migrateAccount" withName:@"MigrateAccount"];
    
    // LIVE OPS
    [self registerRoute:@"metagame.liveOpsSpinWheel.spinWheel" withName:@"SpinWheel"];
    [self registerRoute:@"metagame.liveopsHandler.getLiveopsPromos" withName:@"GetLiveopsPromos"];
    
    // PIGGY BANK
    [self registerRoute:@"metagame.piggyBankHandler.openPiggyBank" withName:@"OpenPiggyBank"];
    [self registerRoute:@"metagame.piggyBankHandler.canOpenPiggyBank" withName:@"CanOpenPiggyBank"];
    
    // SUBSCRIPTION
    [self registerRoute:@"metagame.subscriptionHandler.getPlayerSubscription" withName:@"GetSubscription"];
    [self registerRoute:@"metagame.subscriptionHandler.claim" withName:@"ClaimSubscription"];
    
    // BATTLE PASS
    [self registerRoute:@"metagame.battlePassRoadHandler.claimFreeBattlePassRoad" withName:@"ClaimBattlePassFree"];
    [self registerRoute:@"metagame.battlePassRoadHandler.claimPremiumBattlePassRoad" withName:@"ClaimBattlePassPremium"];
    
    // CHEATS (DEV ONLY)
    [self registerRoute:@"metagame.cheatsHandler.giveCurrencies" withName:@"CHEAT_GiveCurrencies"];
    [self registerRoute:@"metagame.cheatsHandler.giveSoftCurrency" withName:@"CHEAT_GiveCoins"];
    [self registerRoute:@"metagame.cheatsHandler.giveHardCurrency" withName:@"CHEAT_GiveGems"];
    [self registerRoute:@"metagame.cheatsHandler.giveEnergy" withName:@"CHEAT_GiveEnergy"];
    [self registerRoute:@"metagame.cheatsHandler.giveTrophies" withName:@"CHEAT_GiveTrophies"];
    [self registerRoute:@"metagame.cheatsHandler.unlockAllCharacters" withName:@"CHEAT_UnlockAllChars"];
    [self registerRoute:@"metagame.cheatsHandler.unlockAllSkins" withName:@"CHEAT_UnlockAllSkins"];
    [self registerRoute:@"metagame.cheatsHandler.unlockAllItems" withName:@"CHEAT_UnlockAllItems"];
    [self registerRoute:@"metagame.cheatsHandler.testFindMatch" withName:@"CHEAT_TestFindMatch"];
    
    ZPLog(@"Registered %lu routes", (unsigned long)_routeMappings.count);
}

- (void)registerRoute:(NSString *)route withName:(NSString *)name {
    if (route && name) {
        _routeMappings[route] = name;
    }
}

- (NSString *)shortNameForRoute:(NSString *)route {
    return _routeMappings[route] ?: [route componentsSeparatedByString:@"."].lastObject;
}

#pragma mark - Message Capture

- (void)captureMessage:(ZPProtoMessageInfo *)msg {
    [_mutableMessages addObject:msg];
    
    if (_mutableMessages.count > 1000) {
        [_mutableMessages removeObjectsInRange:NSMakeRange(0, _mutableMessages.count - 1000)];
    }
    
    NSString *dirStr = msg.direction == ZPProtoDirectionSend ? @"📤 SEND" : @"📥 RECV";
    NSString *shortName = msg.messageName ?: msg.route;
    
    ZPLog(@"%@ %@ route=%@ size=%lu", 
          dirStr, shortName, msg.route,
          (unsigned long)(msg.payload ? msg.payload.length : 0));
    
    if (msg.parsedData && msg.parsedData.count > 0) {
        NSArray *keys = [msg.parsedData.allKeys sortedArrayUsingSelector:@selector(compare:)];
        for (NSString *key in keys) {
            id value = msg.parsedData[key];
            ZPLog(@"    %@ = %@", key, value);
        }
    }
    
    if (_onMessageCaptured) {
        _onMessageCaptured(msg);
    }
}

#pragma mark - Hook Installation

- (void)installHooks {
    ZPLog(@"Installing ProtoInterceptor hooks (fishhook)...");
    
    struct rebinding rebindings[4];
    rebindings[0] = (struct rebinding){"send", hooked_send, (void **)&original_send};
    rebindings[1] = (struct rebinding){"recv", hooked_recv, (void **)&original_recv};
    rebindings[2] = (struct rebinding){"write", hooked_write, (void **)&original_write};
    rebindings[3] = (struct rebinding){"read", hooked_read, (void **)&original_read};
    
    rebind_symbols(rebindings, 4);
    
    ZPLog(@"ProtoInterceptor hooks installed! Capturing %lu routes...", (unsigned long)_routeMappings.count);
}

- (void)uninstallHooks {
    ZPLog(@"ProtoInterceptor hooks disabled");
    _enabled = NO;
}

#pragma mark - Captured Messages

- (NSArray<ZPProtoMessageInfo *> *)capturedMessages {
    return [_mutableMessages copy];
}

- (void)clearMessages {
    [_mutableMessages removeAllObjects];
}

@end
