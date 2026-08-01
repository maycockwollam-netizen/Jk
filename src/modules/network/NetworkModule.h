//
//  NetworkModule.h
//  ZoobaProto
//
//  Network traffic monitoring
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NetworkModule : NSObject

// Setup
- (void)setup;
- (void)teardown;

// Hook installation
- (void)installHooks;

// Monitoring
- (void)onRequest:(NSURLRequest *)request;
- (void)onResponse:(NSHTTPURLResponse *)response data:(nullable NSData *)data;

// Token detection
- (void)checkForTokenInHeaders:(NSDictionary *)headers;
- (void)checkForTokenInBody:(nullable NSData *)body;

@end

NS_ASSUME_NONNULL_END
