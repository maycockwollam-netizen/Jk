//
//  CoreModule.h
//  ZoobaProto
//
//  Core module - manages other modules and lifecycle
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CoreModule : NSObject

// Setup/Teardown
- (void)setup;
- (void)teardown;

// Module management
- (void)registerModule:(id)module withName:(NSString *)name;
- (void)unregisterModule:(NSString *)name;
- (nullable id)moduleForName:(NSString *)name;

// Lifecycle
- (void)applicationDidLaunch;
- (void)applicationWillTerminate;

// Utils
- (void)logStatus;

@end

NS_ASSUME_NONNULL_END
