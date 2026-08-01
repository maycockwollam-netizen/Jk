//
//  StorageModule.h
//  ZoobaProto
//
//  Token storage and retrieval
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ZPStorageType) {
    ZPStorageTypeUserDefaults = 0,
    ZPStorageTypeKeychain = 1,
    ZPStorageTypeFile = 2
};

@interface ZPToken : NSObject

@property (nonatomic, strong) NSString *key;
@property (nonatomic, strong) NSString *value;
@property (nonatomic, strong, nullable) NSString *bearerFormat;
@property (nonatomic, assign) ZPStorageType storageType;
@property (nonatomic, strong) NSDate *foundAt;

- (instancetype)initWithKey:(NSString *)key value:(NSString *)value;
- (instancetype)initWithKey:(NSString *)key value:(NSString *)value type:(ZPStorageType)type;
- (NSString *)bearerString;

@end

@interface StorageModule : NSObject

// Singleton
+ (instancetype)shared;

// Setup
- (void)setup;
- (void)teardown;

// Token Operations
- (nullable NSString *)findBearerToken;
- (nullable NSString *)findAccessToken;
- (nullable NSString *)findPlayerId;
- (nullable NSString *)findSessionToken;

// Dump
- (void)dumpAllTokens;
- (NSArray<ZPToken *> *)dumpFromUserDefaults;
- (NSArray<ZPToken *> *)dumpFromKeychain;

// Save
- (void)saveToken:(NSString *)token;
- (void)saveToken:(NSString *)token withKey:(NSString *)key;

// Proto Definitions
- (void)saveProtoDefinitions:(NSDictionary *)protoData;
- (NSArray *)getAllProtoDefinitions;
- (void)clearProtoDefinitions;

// Clear
- (void)clearAllTokens;

@end

NS_ASSUME_NONNULL_END
