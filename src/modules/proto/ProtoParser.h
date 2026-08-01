//
//  ProtoParser.h
//  ZoobaProto
//
//  ProtoBuf message parser and analyzer
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Proto Message

@interface ZPProtoField : NSObject
@property (nonatomic, assign) NSInteger fieldNumber;
@property (nonatomic, copy) NSString *fieldName;
@property (nonatomic, copy) NSString *fieldType;
@property (nonatomic, strong, nullable) id fieldValue;
@property (nonatomic, assign) BOOL isRepeated;
@property (nonatomic, assign) BOOL isMessage;

- (NSString *)formattedValue;
- (NSDictionary *)toDictionary;
@end

@interface ZPProtoMessage : NSObject
@property (nonatomic, copy) NSString *messageName;
@property (nonatomic, strong) NSArray<ZPProtoField *> *fields;
@property (nonatomic, strong, nullable) NSDictionary *rawData;

- (instancetype)initWithName:(NSString *)name data:(NSData *)data;
- (instancetype)initWithName:(NSString *)name dictionary:(NSDictionary *)dict;
- (NSString *)toJSONString;
- (NSDictionary *)toDictionary;
- (void)logContents;
@end

#pragma mark - Proto Message Registry

@interface ZPProtoRegistry : NSObject

+ (instancetype)shared;

// Register known messages
- (void)registerKnownMessages;

// Find message class by name
- (Class _Nullable)messageClassForName:(NSString *)name;

// Parse raw data
- (ZPProtoMessage * _Nullable)parseData:(NSData *)data messageName:(NSString *)name;

// Known message types
- (NSArray<NSString *> *)allKnownMessageNames;
- (NSArray<NSString *> *)authRelatedMessages;
- (NSArray<NSString *> *)playerRelatedMessages;
- (NSArray<NSString *> *)matchRelatedMessages;

@end

#pragma mark - ProtoParser Module

@interface ProtoParser : NSObject

+ (instancetype)shared;

// Setup
- (void)setup;
- (void)teardown;

// Hook ProtoBuf methods
- (void)installHooks;

// Parse captured data
- (void)parseProtoMessage:(NSData *)data messageName:(NSString *)name;

// Capture callbacks
@property (nonatomic, copy, nullable) void (^onProtoMessageCaptured)(ZPProtoMessage *message);

@end

NS_ASSUME_NONNULL_END
