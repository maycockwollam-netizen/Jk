//
//  ProtoInterceptor.mm
//  ZoobaProto
//
//  ProtoBuf message interceptor using fishhook
//

#import "ProtoInterceptor.h"
#import "Config.h"
#import <fishhook/fishhook.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>

#define ZPLog(fmt, args...) \
    if (self.enabled && self.logToConsole) { \
        NSLog(@"[ZoobaProto/ProtoInterceptor] " fmt, ##args); \
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
    return [NSString stringWithFormat:@"<ZPProtoMessage: %@ %@ route=%d id=%d size=%lu>",
            _direction == ZPProtoDirectionSend ? @"SEND" : @"RECV",
            _messageName ?: @"Unknown",
            _routeType, _routeId,
            (unsigned long)(_rawData ? _rawData.length : 0)];
}

@end

#pragma mark - ProtoInterceptor Private

@interface ProtoInterceptor ()
@property (nonatomic, strong) NSMutableArray<ZPProtoMessageInfo *> *mutableMessages;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSString *> *routeMappings;
@end

#pragma mark - Original Function Pointers

// Socket functions
static int (*original_send)(int sockfd, const void *buf, size_t len, int flags);
static int (*original_recv)(int sockfd, void *buf, size_t len, int flags);
static int (*original_write)(int fd, const void *buf, size_t count);
static int (*original_read)(int fd, void *buf, size_t count);

// SSL functions
static int (*original_SSLWrite)(void *ssl, void *buf, int num);
static int (*original_SSLRead)(void *ssl, void *buf, int num);

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
        NSData *data = [NSData dataWithBytes:buf length:len];
        
        // Check if it's likely Pitaya/Protobuf data
        if ([interceptor isLikelyProtobufData:data direction:ZPProtoDirectionSend]) {
            ZPProtoMessageInfo *msg = [[ZPProtoMessageInfo alloc] init];
            msg.direction = ZPProtoDirectionSend;
            msg.rawData = data;
            [interceptor parseAndLogMessage:msg];
        }
    } @catch (NSException *e) {
        // Silently ignore
    }
    
    return original_send(sockfd, buf, len, flags);
}

static int hooked_recv(int sockfd, void *buf, size_t len, int flags) {
    int result = original_recv(sockfd, buf, len, flags);
    
    if (result <= 4) {
        return result;
    }
    
    ProtoInterceptor *interceptor = [ProtoInterceptor shared];
    if (!interceptor.enabled) {
        return result;
    }
    
    @try {
        NSData *data = [NSData dataWithBytes:buf length:result];
        
        // Check if it's likely Pitaya/Protobuf data
        if ([interceptor isLikelyProtobufData:data direction:ZPProtoDirectionRecv]) {
            ZPProtoMessageInfo *msg = [[ZPProtoMessageInfo alloc] init];
            msg.direction = ZPProtoDirectionRecv;
            msg.rawData = data;
            [interceptor parseAndLogMessage:msg];
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
        NSData *data = [NSData dataWithBytes:buf length:count];
        
        if ([interceptor isLikelyProtobufData:data direction:ZPProtoDirectionSend]) {
            ZPProtoMessageInfo *msg = [[ZPProtoMessageInfo alloc] init];
            msg.direction = ZPProtoDirectionSend;
            msg.rawData = data;
            [interceptor parseAndLogMessage:msg];
        }
    } @catch (NSException *e) {
        // Silently ignore
    }
    
    return original_write(fd, buf, count);
}

static int hooked_read(int fd, void *buf, size_t count) {
    int result = original_read(fd, buf, count);
    
    if (result <= 4) {
        return result;
    }
    
    ProtoInterceptor *interceptor = [ProtoInterceptor shared];
    if (!interceptor.enabled) {
        return result;
    }
    
    @try {
        NSData *data = [NSData dataWithBytes:buf length:result];
        
        if ([interceptor isLikelyProtobufData:data direction:ZPProtoDirectionRecv]) {
            ZPProtoMessageInfo *msg = [[ZPProtoMessageInfo alloc] init];
            msg.direction = ZPProtoDirectionRecv;
            msg.rawData = data;
            [interceptor parseAndLogMessage:msg];
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
        [self registerDefaultRoutes];
    }
    return self;
}

- (void)setup {
    ZPLog(@"ProtoInterceptor setup");
}

- (void)teardown {
    [self uninstallHooks];
    [_mutableMessages removeAllObjects];
}

#pragma mark - Route Mappings

- (void)registerDefaultRoutes {
    // Pitaya uses route IDs for routing messages
    // These are common IDs - actual ones need to be found from binary
    
    // Auth
    [self registerRouteId:1 withName:@"AuthenticatePlayer"];
    [self registerRouteId:2 withName:@"AuthenticateAnswer"];
    [self registerRouteId:3 withName:@"Heartbeat"];
    
    // Match
    [self registerRouteId:10 withName:@"FindMatch"];
    [self registerRouteId:11 withName:@"FindMatchAnswer"];
    [self registerRouteId:12 withName:@"StartMatch"];
    [self registerRouteId:13 withName:@"MatchData"];
    [self registerRouteId:14 withName:@"FinishMatch"];
    
    // Chest
    [self registerRouteId:20 withName:@"OpenChest"];
    [self registerRouteId:21 withName:@"OpenChestAnswer"];
    [self registerRouteId:22 withName:@"ChestData"];
    
    // Inventory
    [self registerRouteId:30 withName:@"GetInventory"];
    [self registerRouteId:31 withName:@"InventoryData"];
    
    // Purchase
    [self registerRouteId:40 withName:@"Purchase"];
    [self registerRouteId:41 withName:@"PurchaseAnswer"];
    
    // Clan
    [self registerRouteId:50 withName:@"GetClan"];
    [self registerRouteId:51 withName:@"ClanData"];
    
    // Generic
    [self registerRouteId:100 withName:@"Unknown"];
}

- (void)registerRouteId:(uint16_t)routeId withName:(NSString *)name {
    _routeMappings[@(routeId)] = name;
}

- (NSString *)routeNameForId:(uint16_t)routeId {
    return _routeMappings[@(routeId)] ?: [NSString stringWithFormat:@"Route_%d", routeId];
}

#pragma mark - Data Detection

- (BOOL)isLikelyProtobufData:(NSData *)data direction:(ZPProtoDirection)direction {
    if (!data || data.length < 4) return NO;
    
    const uint8_t *bytes = data.bytes;
    
    // Pitaya packet format:
    // [type:2bytes][route_id:2bytes][protobuf_data...]
    
    // Check first 4 bytes look like a valid header
    // Type should be 0x01 (request), 0x02 (response), or 0x03 (notify)
    
    uint8_t type = bytes[0];
    if (type > 0x05) return NO;  // Invalid type
    
    // Route ID should be reasonable
    uint16_t routeId = (bytes[2] << 8) | bytes[3];
    if (routeId == 0 && data.length > 4) {
        // Try other byte order
        routeId = (bytes[3] << 8) | bytes[2];
    }
    
    // Check if protobuf data starts after header
    if (data.length > 4) {
        uint8_t protoStart = bytes[4];
        // Protobuf starts with tag (0-10 typically for small fields)
        // or varint for string length
        if (protoStart > 0x80) {
            // Could be compressed, skip
            return YES;
        }
    }
    
    return YES;  // Assume it's protobuf if it looks like a packet
}

#pragma mark - Parse Message

- (void)parseAndLogMessage:(ZPProtoMessageInfo *)msg {
    if (!msg.rawData || msg.rawData.length < 4) return;
    
    const uint8_t *bytes = msg.rawData.bytes;
    
    // Parse Pitaya header
    msg.routeType = bytes[0];
    msg.routeId = (bytes[2] << 8) | bytes[3];
    
    // Get route name
    msg.messageName = [self routeNameForId:msg.routeId];
    
    // Extract payload (everything after header)
    if (msg.rawData.length > 4) {
        msg.payload = [msg.rawData subdataWithRange:NSMakeRange(4, msg.rawData.length - 4)];
    }
    
    // Try to parse protobuf
    [self tryParseProtobuf:msg];
    
    // Store message
    [_mutableMessages addObject:msg];
    
    // Keep only last 1000 messages
    if (_mutableMessages.count > 1000) {
        [_mutableMessages removeObjectsInRange:NSMakeRange(0, _mutableMessages.count - 1000)];
    }
    
    // Log to console
    NSString *dirStr = msg.direction == ZPProtoDirectionSend ? @"📤 SEND" : @"📥 RECV";
    ZPLog(@"%@ Route:%@ (%d) Size:%lu", 
          dirStr, msg.messageName, msg.routeId, 
          (unsigned long)(msg.payload ? msg.payload.length : 0));
    
    // Fire callback
    if (_onMessageCaptured) {
        _onMessageCaptured(msg);
    }
}

- (void)tryParseProtobuf:(ZPProtoMessageInfo *)msg {
    if (!msg.payload || msg.payload.length == 0) return;
    
    NSMutableDictionary *parsed = [NSMutableDictionary dictionary];
    const uint8_t *bytes = msg.payload.bytes;
    NSUInteger offset = 0;
    NSUInteger length = msg.payload.length;
    
    while (offset < length) {
        uint8_t fieldTag = bytes[offset];
        offset++;
        
        // Decode field number and wire type
        uint32_t fieldNumber = fieldTag >> 3;
        uint32_t wireType = fieldTag & 0x07;
        
        NSString *fieldName = [NSString stringWithFormat:@"field_%d", fieldNumber];
        
        switch (wireType) {
            case 0: {  // Varint
                uint64_t value = 0;
                uint8_t shift = 0;
                while (offset < length) {
                    uint8_t b = bytes[offset++];
                    value |= (b & 0x7F) << shift;
                    if ((b & 0x80) == 0) break;
                    shift += 7;
                }
                parsed[fieldName] = @(value);
                break;
            }
            case 1: {  // 64-bit
                if (offset + 8 <= length) {
                    uint64_t value = 0;
                    for (int i = 0; i < 8; i++) {
                        value = (value << 8) | bytes[offset + i];
                    }
                    parsed[fieldName] = @(value);
                    offset += 8;
                }
                break;
            }
            case 2: {  // Length-delimited (string, bytes, etc.)
                uint32_t len = 0;
                uint8_t shift = 0;
                NSUInteger lenOffset = offset;
                while (lenOffset < length) {
                    uint8_t b = bytes[lenOffset++];
                    len |= (b & 0x7F) << shift;
                    if ((b & 0x80) == 0) break;
                    shift += 7;
                }
                offset = lenOffset;
                
                if (offset + len <= length) {
                    NSData *fieldData = [msg.payload subdataWithRange:NSMakeRange(offset, len)];
                    
                    // Try to decode as string
                    NSString *str = [[NSString alloc] initWithData:fieldData encoding:NSUTF8StringEncoding];
                    if (str) {
                        parsed[fieldName] = str;
                    } else {
                        // Store as hex
                        NSMutableString *hex = [NSMutableString string];
                        const uint8_t *hexBytes = fieldData.bytes;
                        for (NSUInteger i = 0; i < fieldData.length && i < 100; i++) {
                            [hex appendFormat:@"%02X", hexBytes[i]];
                        }
                        if (fieldData.length > 100) [hex appendString:@"..."];
                        parsed[fieldName] = [NSString stringWithFormat:@"<%lu bytes: %@>", 
                                             (unsigned long)fieldData.length, hex];
                    }
                    offset += len;
                }
                break;
            }
            case 5: {  // 32-bit
                if (offset + 4 <= length) {
                    uint32_t value = 0;
                    for (int i = 0; i < 4; i++) {
                        value = (value << 8) | bytes[offset + i];
                    }
                    parsed[fieldName] = @(value);
                    offset += 4;
                }
                break;
            }
            default:
                // Unknown wire type, skip to next byte
                if (offset < length) offset++;
                break;
        }
    }
    
    if (parsed.count > 0) {
        msg.parsedData = parsed;
    }
}

#pragma mark - Hook Installation

- (void)installHooks {
    ZPLog(@"Installing ProtoInterceptor hooks...");
    
    int rebound = 0;
    struct rebinding rebindings[4];
    
    // Hook send
    rebindings[rebound].name = "send";
    rebindings[rebound].replacement = hooked_send;
    rebindings[rebound].replaced = (void **)&original_send;
    rebound++;
    
    // Hook recv
    rebindings[rebound].name = "recv";
    rebindings[rebound].replacement = hooked_recv;
    rebindings[rebound].replaced = (void **)&original_recv;
    rebound++;
    
    // Hook write
    rebindings[rebound].name = "write";
    rebindings[rebound].replacement = hooked_write;
    rebindings[rebound].replaced = (void **)&original_write;
    rebound++;
    
    // Hook read
    rebindings[rebound].name = "read";
    rebindings[rebound].replacement = hooked_read;
    rebindings[rebound].replaced = (void **)&original_read;
    rebound++;
    
    rebind_symbols(rebindings, rebound);
    
    ZPLog(@"ProtoInterceptor hooks installed! Capturing socket traffic...");
}

- (void)uninstallHooks {
    ZPLog(@"Uninstalling ProtoInterceptor hooks...");
    // Note: fishhook doesn't support uninstall, but we disable via _enabled flag
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
