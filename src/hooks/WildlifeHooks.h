//
//  WildlifeHooks.h
//  ZoobaProto
//
//  Hooks for Wildlife Studios classes
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WildlifeHooks : NSObject

// Installation
+ (void)install;
+ (void)uninstall;

// Class discovery
+ (void)discoverWildlifeClasses;
+ (void)hookClass:(Class)cls;

@end

NS_ASSUME_NONNULL_END
