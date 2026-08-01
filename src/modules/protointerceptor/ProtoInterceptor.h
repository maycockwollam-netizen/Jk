//
//  ProtoInterceptor.h
//  ZoobaProto
//
//  ProtoBuf message interceptor using fishhook
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Message Types

typedef NS_ENUM(NSInteger, ZPProtoDirection) {
    ZPProtoDirectionSend = 0,
    ZPProtoDirectionRecv = 1
};

#pragma mark - Proto Message Info

@interface ZPProtoMessageInfo : NSObject
@property (nonatomic, copy) NSString *route;         // Full route string (e.g., "metagame.playerHandler.authenticate")
@property (nonatomic, copy) NSString *messageName;    // Short name (e.g., "Authenticate")
@property (nonatomic, assign) ZPProtoDirection direction;
@property (nonatomic, strong) NSData *rawData;
@property (nonatomic, assign) uint8_t msgType;        // Pitaya message type
@property (nonatomic, assign) uint32_t requestId;     // Request ID (for response matching)
@property (nonatomic, strong) NSData *payload;       // Raw protobuf data
@property (nonatomic, strong) NSDate *timestamp;
@property (nonatomic, strong, nullable) NSDictionary *parsedData;
@end

#pragma mark - ProtoInterceptor

@interface ProtoInterceptor : NSObject

+ (instancetype)shared;

// Setup
- (void)setup;
- (void)teardown;

// Install hooks
- (void)installHooks;
- (void)uninstallHooks;

// Enable/Disable
@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, assign) BOOL logToConsole;

// Captured messages
@property (nonatomic, readonly) NSArray<ZPProtoMessageInfo *> *capturedMessages;
- (void)clearMessages;
- (void)captureMessage:(ZPProtoMessageInfo *)msg;

// Callbacks
@property (nonatomic, copy, nullable) void (^onMessageCaptured)(ZPProtoMessageInfo *message);

// Route mappings (Pitaya uses STRING routes!)
- (void)registerRoute:(NSString *)route withName:(NSString *)name;
- (NSString *)shortNameForRoute:(NSString *)route;

@end

NS_ASSUME_NONNULL_END
