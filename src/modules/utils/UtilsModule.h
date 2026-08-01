//
//  UtilsModule.h
//  ZoobaProto
//
//  Utility functions and helpers
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface UtilsModule : NSObject

// Singleton
+ (instancetype)shared;

// Setup
- (void)setup;
- (void)teardown;

// Notifications
- (void)notifyTokenFound:(NSString *)token;
- (void)notifyEvent:(NSString *)eventName data:(nullable NSDictionary *)data;

// Logging
- (void)logHexDump:(NSData *)data label:(nullable NSString *)label;
- (void)logSeparator;

// File operations
- (NSString *)documentsPath;
- (NSString *)tempPath;
- (BOOL)writeData:(NSData *)data toFile:(NSString *)filename;
- (nullable NSData *)readDataFromFile:(NSString *)filename;

// String utilities
- (BOOL)isValidJWT:(NSString *)string;
- (nullable NSString *)extractBearerToken:(NSString *)string;
- (nullable NSString *)hexDumpString:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
