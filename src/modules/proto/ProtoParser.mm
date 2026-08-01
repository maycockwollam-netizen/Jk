//
//  ProtoParser.mm
//  ZoobaProto
//
//  ProtoBuf message parser and analyzer
//

#import "ProtoParser.h"
#import "config/Config.h"
#import <objc/runtime.h>

#define ZPLog(fmt, args...) NSLog(@"[ZoobaProto/Proto] " fmt, ##args)

#pragma mark - ZPProtoField

@implementation ZPProtoField

- (NSString *)formattedValue {
    if (!_fieldValue) return @"null";
    
    if ([_fieldValue isKindOfClass:[NSString class]]) {
        NSString *str = (NSString *)_fieldValue;
        if (str.length > 100) {
            return [NSString stringWithFormat:@"\"%@...\"", [str substringToIndex:100]];
        }
        return [NSString stringWithFormat:@"\"%@\"", str];
    }
    
    if ([_fieldValue isKindOfClass:[NSData class]]) {
        NSData *data = (NSData *)_fieldValue;
        if (data.length > 50) {
            return [NSString stringWithFormat:@"<Data: %lu bytes>", (unsigned long)data.length];
        }
        return [NSString stringWithFormat:@"<Data: %lu bytes>", (unsigned long)data.length];
    }
    
    if ([_fieldValue isKindOfClass:[NSDictionary class]]) {
        return @"{...}"; // Simplified
    }
    
    if ([_fieldValue isKindOfClass:[NSArray class]]) {
        return [NSString stringWithFormat:@"[%lu items]", (unsigned long)[(NSArray *)_fieldValue count]];
    }
    
    return [_fieldValue description];
}

- (NSDictionary *)toDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"fieldNumber"] = @(_fieldNumber);
    dict[@"fieldName"] = _fieldName ?: @"";
    dict[@"fieldType"] = _fieldType ?: @"";
    if (_fieldValue) {
        dict[@"fieldValue"] = _fieldValue;
    }
    dict[@"isRepeated"] = @(_isRepeated);
    dict[@"isMessage"] = @(_isMessage);
    return dict;
}

@end

#pragma mark - ZPProtoMessage

@implementation ZPProtoMessage

- (instancetype)initWithName:(NSString *)name data:(NSData *)data {
    self = [super init];
    if (self) {
        _messageName = name;
        _rawData = nil;
        _fields = @[];
        
        // Try to parse protobuf
        [self parseProtobufData:data];
    }
    return self;
}

- (instancetype)initWithName:(NSString *)name dictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _messageName = name;
        _rawData = dict;
        _fields = [self fieldsFromDictionary:dict];
    }
    return self;
}

- (void)parseProtobufData:(NSData *)data {
    if (!data || data.length == 0) return;
    
    NSMutableArray<ZPProtoField *> *parsedFields = [NSMutableArray array];
    NSMutableData *mutableData = [data mutableCopy];
    
    const uint8_t *bytes = (const uint8_t *)mutableData.bytes;
    NSUInteger length = mutableData.length;
    NSUInteger offset = 0;
    
    while (offset < length) {
        ZPProtoField *field = [self readField:bytes length:length offset:&offset];
        if (field) {
            [parsedFields addObject:field];
        } else {
            break;
        }
    }
    
    _fields = parsedFields;
}

- (ZPProtoField *)readField:(const uint8_t *)bytes length:(NSUInteger)length offset:(NSUInteger *)offset {
    if (*offset >= length) return nil;
    
    // Read tag
    uint32_t tag = 0;
    int shift = 0;
    while (*offset < length) {
        uint8_t byte = bytes[(*offset)++];
        tag |= (byte & 0x7F) << shift;
        if ((byte & 0x80) == 0) break;
        shift += 7;
        if (shift > 28) return nil;
    }
    
    // Decode field number and wire type
    uint32_t fieldNumber = tag >> 3;
    uint32_t wireType = tag & 0x7;
    
    ZPProtoField *field = [[ZPProtoField alloc] init];
    field.fieldNumber = fieldNumber;
    
    // Try to get field name from registry
    field.fieldName = [self fieldNameForNumber:fieldNumber inMessage:_messageName];
    
    // Read value based on wire type
    switch (wireType) {
        case 0: // Varint
        {
            uint64_t value = 0;
            shift = 0;
            while (*offset < length) {
                uint8_t byte = bytes[(*offset)++];
                value |= (byte & 0x7F) << shift;
                if ((byte & 0x80) == 0) break;
                shift += 7;
            }
            field.fieldValue = @(value);
            field.fieldType = @"int64";
        }
        break;
        
        case 1: // 64-bit
        {
            uint64_t value = 0;
            for (int i = 0; i < 8 && *offset < length; i++) {
                value |= ((uint64_t)bytes[(*offset)++]) << (i * 8);
            }
            field.fieldValue = @(value);
            field.fieldType = @"fixed64";
        }
        break;
        
        case 2: // Length-delimited
        {
            // Read length
            uint32_t len = 0;
            shift = 0;
            while (*offset < length) {
                uint8_t byte = bytes[(*offset)++];
                len |= (byte & 0x7F) << shift;
                if ((byte & 0x80) == 0) break;
                shift += 7;
            }
            
            if (*offset + len <= length) {
                NSData *subData = [NSData dataWithBytes:bytes + *offset length:len];
                
                // Try to decode as string
                NSString *str = [[NSString alloc] initWithData:subData encoding:NSUTF8StringEncoding];
                if (str) {
                    field.fieldValue = str;
                    field.fieldType = @"string";
                } else {
                    // Check if it's a nested message
                    field.fieldValue = subData;
                    field.fieldType = @"bytes";
                    field.isMessage = YES;
                }
            }
            *offset += len;
        }
        break;
        
        case 5: // 32-bit
        {
            uint32_t value = 0;
            for (int i = 0; i < 4 && *offset < length; i++) {
                value |= ((uint32_t)bytes[(*offset)++]) << (i * 8);
            }
            field.fieldValue = @(value);
            field.fieldType = @"fixed32";
        }
        break;
        
        default:
        return nil;
    }
    
    return field;
}

- (NSArray<ZPProtoField *> *)fieldsFromDictionary:(NSDictionary *)dict {
    NSMutableArray<ZPProtoField *> *fields = [NSMutableArray array];
    
    for (NSString *key in dict) {
        ZPProtoField *field = [[ZPProtoField alloc] init];
        field.fieldName = key;
        field.fieldValue = dict[key];
        [fields addObject:field];
    }
    
    return fields;
}

- (NSString *)fieldNameForNumber:(NSInteger)number inMessage:(NSString *)messageName {
    // Lookup from known message definitions
    NSDictionary *knownFields = [self knownFieldsForMessage:messageName];
    return knownFields[@(number)] ?: [NSString stringWithFormat:@"field_%ld", (long)number];
}

- (NSDictionary *)knownFieldsForMessage:(NSString *)messageName {
    // AuthenticatePlayerArgs fields
    static NSDictionary *authenticatePlayerArgs = nil;
    static dispatch_once_t onceToken1;
    dispatch_once(&onceToken1, ^{
        authenticatePlayerArgs = @{
            @1: @"accessToken",
            @2: @"locale",
            @3: @"syncPlayer",
            @4: @"localAbTests",
            @5: @"remoteConfigArgs",
            @6: @"deviceSettings",
            @7: @"serverAutoRegion",
            @8: @"playerChosenRegion",
            @9: @"isChild"
        };
    });
    
    // AuthenticatePlayerAnswer fields
    static NSDictionary *authenticatePlayerAnswer = nil;
    static dispatch_once_t onceToken2;
    dispatch_once(&onceToken2, ^{
        authenticatePlayerAnswer = @{
            @1: @"code",
            @2: @"token",
            @3: @"timestampUtc",
            @4: @"dataPlayer",
            @5: @"dataInventory",
            @6: @"dataPlayerChests",
            @7: @"dataMatchInfo",
            @9: @"dataItems",
            @10: @"dataLoadouts",
            @11: @"configHash",
            @12: @"dataMissions",
            @13: @"dataClan",
            @14: @"piggyBank",
            @15: @"team",
            @16: @"subscription"
        };
    });
    
    // DataPlayer fields
    static NSDictionary *dataPlayer = nil;
    static dispatch_once_t onceToken3;
    dispatch_once(&onceToken3, ^{
        dataPlayer = @{
            @1: @"id",
            @2: @"name",
            @3: @"level",
            @4: @"xp",
            @5: @"coins",
            @6: @"gems",
            @7: @"trophies",
            @8: @"wins",
            @9: @"losses"
        };
    });
    
    if ([messageName isEqualToString:@"AuthenticatePlayerArgs"]) return authenticatePlayerArgs;
    if ([messageName isEqualToString:@"AuthenticatePlayerAnswer"]) return authenticatePlayerAnswer;
    if ([messageName isEqualToString:@"DataPlayer"]) return dataPlayer;
    
    return @{};
}

- (NSString *)toJSONString {
    NSDictionary *dict = [self toDictionary];
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
    if (jsonData) {
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    return @"{}";
}

- (NSDictionary *)toDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"messageName"] = _messageName ?: @"";
    
    NSMutableArray *fieldsArray = [NSMutableArray array];
    for (ZPProtoField *field in _fields) {
        [fieldsArray addObject:[field toDictionary]];
    }
    dict[@"fields"] = fieldsArray;
    
    return dict;
}

- (void)logContents {
    ZPLog(@"=== Proto Message: %@ ===", _messageName);
    ZPLog(@"Fields: %lu", (unsigned long)_fields.count);
    
    for (ZPProtoField *field in _fields) {
        ZPLog(@"  [%ld] %@ (%@) = %@", 
              (long)field.fieldNumber, 
              field.fieldName ?: @"unknown", 
              field.fieldType ?: @"",
              [field formattedValue]);
    }
}

@end

#pragma mark - ZPProtoRegistry

@implementation ZPProtoRegistry

+ (instancetype)shared {
    static ZPProtoRegistry *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ZPProtoRegistry alloc] init];
        [instance registerKnownMessages];
    });
    return instance;
}

- (void)registerKnownMessages {
    ZPLog(@"Registering known proto messages...");
    
    // Auth related
    [self registerMessage:@"AuthenticatePlayerArgs" category:@"auth"];
    [self registerMessage:@"AuthenticatePlayerAnswer" category:@"auth"];
    [self registerMessage:@"OnSessionBindArgs" category:@"auth"];
    [self registerMessage:@"OnSessionCloseArgs" category:@"auth"];
    [self registerMessage:@"DataAccountMigration" category:@"auth"];
    
    // Player related
    [self registerMessage:@"DataPlayer" category:@"player"];
    [self registerMessage:@"Player" category:@"player"];
    [self registerMessage:@"PlayerEnterArgs" category:@"player"];
    [self registerMessage:@"PlayerEnterAnswer" category:@"player"];
    [self registerMessage:@"PlayerExitArgs" category:@"player"];
    [self registerMessage:@"PlayerExitAnswer" category:@"player"];
    [self registerMessage:@"GetPlayerProfileAnswer" category:@"player"];
    [self registerMessage:@"PlayerStats" category:@"player"];
    [self registerMessage:@"PlayerMembership" category:@"player"];
    
    // Match related
    [self registerMessage:@"FindMatchArgs" category:@"match"];
    [self registerMessage:@"FindMatchAnswer" category:@"match"];
    [self registerMessage:@"StartMatchArgs" category:@"match"];
    [self registerMessage:@"FinishMatchArgs" category:@"match"];
    [self registerMessage:@"Match" category:@"match"];
    [self registerMessage:@"MatchPlayer" category:@"match"];
    [self registerMessage:@"GetMatchPlayersArgs" category:@"match"];
    [self registerMessage:@"GetMatchPlayersAnswer" category:@"match"];
    
    // Team/Clan related
    [self registerMessage:@"Team" category:@"team"];
    [self registerMessage:@"TeamMember" category:@"team"];
    [self registerMessage:@"CreateTeamArgs" category:@"team"];
    [self registerMessage:@"JoinTeamArgs" category:@"team"];
    [self registerMessage:@"InviteFriendToTeamArgs" category:@"team"];
    
    [self registerMessage:@"ClanCreationArgs" category:@"clan"];
    [self registerMessage:@"ClanCreationAnswer" category:@"clan"];
    [self registerMessage:@"GetClanAnswer" category:@"clan"];
    [self registerMessage:@"ClanMember" category:@"clan"];
    [self registerMessage:@"DataClan" category:@"clan"];
    
    // Inventory/Items
    [self registerMessage:@"DataInventory" category:@"inventory"];
    [self registerMessage:@"DataItem" category:@"inventory"];
    [self registerMessage:@"DataItems" category:@"inventory"];
    [self registerMessage:@"Item" category:@"inventory"];
    
    // Chest related
    [self registerMessage:@"ChestData" category:@"chest"];
    [self registerMessage:@"DataChest" category:@"chest"];
    [self registerMessage:@"OpenChestArgs" category:@"chest"];
    [self registerMessage:@"OpenChestAnswer" category:@"chest"];
    
    ZPLog(@"Registered %lu message types", (unsigned long)[self allKnownMessageNames].count);
}

static NSMutableDictionary *g_messageRegistry = nil;
static NSMutableArray *g_authMessages = nil;
static NSMutableArray *g_playerMessages = nil;
static NSMutableArray *g_matchMessages = nil;
static NSMutableArray *g_teamMessages = nil;
static NSMutableArray *g_clanMessages = nil;
static NSMutableArray *g_inventoryMessages = nil;
static NSMutableArray *g_chestMessages = nil;

- (void)registerMessage:(NSString *)name category:(NSString *)category {
    if (!g_messageRegistry) {
        g_messageRegistry = [NSMutableDictionary dictionary];
        g_authMessages = [NSMutableArray array];
        g_playerMessages = [NSMutableArray array];
        g_matchMessages = [NSMutableArray array];
        g_teamMessages = [NSMutableArray array];
        g_clanMessages = [NSMutableArray array];
        g_inventoryMessages = [NSMutableArray array];
        g_chestMessages = [NSMutableArray array];
    }
    
    g_messageRegistry[name] = @YES;
    
    if ([category isEqualToString:@"auth"]) [g_authMessages addObject:name];
    if ([category isEqualToString:@"player"]) [g_playerMessages addObject:name];
    if ([category isEqualToString:@"match"]) [g_matchMessages addObject:name];
    if ([category isEqualToString:@"team"]) [g_teamMessages addObject:name];
    if ([category isEqualToString:@"clan"]) [g_clanMessages addObject:name];
    if ([category isEqualToString:@"inventory"]) [g_inventoryMessages addObject:name];
    if ([category isEqualToString:@"chest"]) [g_chestMessages addObject:name];
}

- (Class _Nullable)messageClassForName:(NSString *)name {
    return g_messageRegistry[name] ? [ZPProtoMessage class] : nil;
}

- (ZPProtoMessage * _Nullable)parseData:(NSData *)data messageName:(NSString *)name {
    if (!data || !name) return nil;
    
    ZPProtoMessage *message = [[ZPProtoMessage alloc] initWithName:name data:data];
    return message;
}

- (NSArray<NSString *> *)allKnownMessageNames {
    return [g_messageRegistry.allKeys sortedArrayUsingSelector:@selector(compare:)];
}

- (NSArray<NSString *> *)authRelatedMessages {
    return [g_authMessages sortedArrayUsingSelector:@selector(compare:)];
}

- (NSArray<NSString *> *)playerRelatedMessages {
    return [g_playerMessages sortedArrayUsingSelector:@selector(compare:)];
}

- (NSArray<NSString *> *)matchRelatedMessages {
    return [g_matchMessages sortedArrayUsingSelector:@selector(compare:)];
}

@end

#pragma mark - ProtoParser Module

@interface ProtoParser ()
@property (nonatomic, strong) NSMutableArray<ZPProtoMessage *> *capturedMessages;
@end

@implementation ProtoParser

+ (instancetype)shared {
    static ProtoParser *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ProtoParser alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _capturedMessages = [NSMutableArray array];
    }
    return self;
}

- (void)setup {
    ZPLog(@"Setting up ProtoParser module...");
    
    // Register known messages
    [[ZPProtoRegistry shared] registerKnownMessages];
    
    // Install hooks
    [self installHooks];
    
    ZPLog(@"ProtoParser module ready");
}

- (void)teardown {
    ZPLog(@"Tearing down ProtoParser module...");
    [_capturedMessages removeAllObjects];
}

#pragma mark - Hook Installation

- (void)installHooks {
    ZPLog(@"Installing ProtoBuf hooks...");
    
    // Hook Google.Protobuf methods if available
    // These are typically in the compiled protobuf library
    
    // Try to find protobuf classes
    Class parserClass = NSClassFromString(@"Google.Protobuf.Parser");
    if (parserClass) {
        ZPLog(@"Found Google.Protobuf.Parser");
        // Hook parse methods
    }
    
    // Try to find message classes
    Class messageClass = NSClassFromString(@"Google.Protobuf.IMessage");
    if (messageClass) {
        ZPLog(@"Found Google.Protobuf.IMessage");
    }
    
    // Hook Pitaya protobuf if available
    Class pitayaProtoClass = NSClassFromString(@"Pitaya.Protobuf.ProtobufSerializer");
    if (pitayaProtoClass) {
        ZPLog(@"Found Pitaya.ProtobufSerializer");
        [self hookPitayaProtobuf:pitayaProtoClass];
    }
    
    ZPLog(@"Proto hooks installed");
}

- (void)hookPitayaProtobuf:(Class)cls {
    // Pitaya uses Protobuf for network messages
    // Hook: Serialize/Deserialize methods
    
    unsigned int methodCount = 0;
    Method *methods = class_copyMethodList(cls, &methodCount);
    
    for (unsigned int i = 0; i < methodCount; i++) {
        Method method = methods[i];
        NSString *methodName = NSStringFromSelector(method_getName(method));
        
        // Hook Serialize/Deserialize
        if ([methodName containsString:@"Encode"] || 
            [methodName containsString:@"Decode"] ||
            [methodName containsString:@"Serialize"] ||
            [methodName containsString:@"Deserialize"]) {
            
            ZPLog(@"  Hooking: %@", methodName);
            [self hookProtobufMethod:cls selector:method_getName(method)];
        }
    }
    
    free(methods);
}

- (void)hookProtobufMethod:(Class)cls selector:(SEL)selector {
    if (![cls instancesRespondToSelector:selector]) return;
    
    Method originalMethod = class_getInstanceMethod(cls, selector);
    if (!originalMethod) return;
    
    IMP originalIMP = method_getImplementation(originalMethod);
    __block IMP original = originalIMP;
    
    IMP swizzledIMP = imp_implementationWithBlock(^(id self, ...){
        va_list args;
        va_start(args, self);
        
        // Call original
        id result = ((id (*)(id, SEL, va_list))original)(self, selector, args);
        
        va_end(args);
        
        return result;
    });
    
    method_setImplementation(originalMethod, swizzledIMP);
}

#pragma mark - Parse Methods

- (void)parseProtoMessage:(NSData *)data messageName:(NSString *)name {
    if (!data || !name) return;
    
    @try {
        ZPProtoMessage *message = [[ZPProtoRegistry shared] parseData:data messageName:name];
        
        if (message) {
            [_capturedMessages addObject:message];
            
            // Log interesting messages
            if ([[[ZPProtoRegistry shared] authRelatedMessages] containsObject:name]) {
                ZPLog(@"🎯 AUTH PROTO: %@", name);
                [message logContents];
            }
            
            // Notify
            if (_onProtoMessageCaptured) {
                _onProtoMessageCaptured(message);
            }
            
            // Post notification
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ZoobaProtoProtoCaptured"
                                                            object:nil
                                                          userInfo:@{@"message": message}];
        }
    } @catch (NSException *exception) {
        ZPLog(@"Exception parsing proto: %@", exception.reason);
    }
}

@end
