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
@property (nonatomic, copy) NSString *messageName;
@property (nonatomic, assign) ZPProtoDirection direction;
@property (nonatomic, strong) NSData *rawData;
@property (nonatomic, assign) uint16_t routeType;  // Pitaya route type (first 2 bytes)
@property (nonatomic, assign) uint16_t routeId;   // Pitaya route ID
@property (nonatomic, strong) NSData *payload;
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

// Callbacks
@property (nonatomic, copy, nullable) void (^onMessageCaptured)(ZPProtoMessageInfo *message);

// Known route mappings (Pitaya uses route IDs)
- (void)registerRouteId:(uint16_t)routeId withName:(NSString *)name;
- (NSString *)routeNameForId:(uint16_t)routeId;

@end

NS_ASSUME_NONNULL_END
