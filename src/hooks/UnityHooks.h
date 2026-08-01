//
//  UnityHooks.h
//  ZoobaProto
//
//  Hooks for Unity classes
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface UnityHooks : NSObject

// Installation
+ (void)install;
+ (void)uninstall;

// Unity PlayerPrefs
+ (void)hookUnityPlayerPrefs;

@end

NS_ASSUME_NONNULL_END
