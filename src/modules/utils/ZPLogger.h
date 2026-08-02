//
//  ZPLogger.h
//  ZoobaProto
//
//  Continuous file logger for debugging
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZPLogger : NSObject

+ (instancetype)shared;

// Start continuous logging
- (void)startLogging;

// Stop logging
- (void)stopLogging;

// Log methods
- (void)log:(NSString *)message;
- (void)logFormat:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2);
- (void)logError:(NSString *)message;
- (void)logSystemInfo;
- (void)logMemoryUsage;
- (void)logTimestamp:(NSString *)event;

// Get log file path
- (NSString *)logFilePath;

// Flush buffer to disk
- (void)flush;

@end

NS_ASSUME_NONNULL_END
