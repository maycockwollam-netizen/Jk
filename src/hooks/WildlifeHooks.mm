//
//  WildlifeHooks.mm
//  ZoobaProto
//
//  Hooks for Wildlife Studios classes
//

#import "WildlifeHooks.h"
#import "Config.h"
#import "StorageModule.h"

#define ZPLog(fmt, args...) NSLog(@"[ZoobaProto/Wildlife] " fmt, ##args)

@implementation WildlifeHooks

+ (void)install {
    ZPLog(@"Installing Wildlife hooks...");
    
    // Discover all Wildlife classes
    [self discoverWildlifeClasses];
    
    // Hook Pitaya classes
    [self hookPitayaClasses];
    
    // Hook Platform classes
    [self hookPlatformClasses];
    
    ZPLog(@"Wildlife hooks installed");
}

+ (void)uninstall {
    ZPLog(@"Uninstalling Wildlife hooks...");
}

#pragma mark - Class Discovery

+ (void)discoverWildlifeClasses {
    ZPLog(@"Discovering Wildlife classes...");
    
    int classCount = objc_getClassList(NULL, 0);
    if (classCount == 0) {
        ZPLog(@"No classes found!");
        return;
    }
    
    Class *classes = (Class *)malloc(sizeof(Class) * classCount);
    objc_getClassList(classes, classCount);
    
    NSArray *prefixes = [Config shared].wildlifeClassPrefixes;
    int foundCount = 0;
    
    for (int i = 0; i < classCount; i++) {
        Class cls = classes[i];
        NSString *className = NSStringFromClass(cls);
        
        for (NSString *prefix in prefixes) {
            if ([className hasPrefix:prefix]) {
                ZPLog(@"Found Wildlife class: %@", className);
                [self hookClass:cls];
                foundCount++;
                break;
            }
        }
    }
    
    free(classes);
    
    ZPLog(@"Discovered %d Wildlife classes", foundCount);
}

+ (void)hookClass:(Class)cls {
    if (!cls) return;
    
    unsigned int methodCount = 0;
    Method *methods = class_copyMethodList(cls, &methodCount);
    
    if (!methods) return;
    
    for (unsigned int i = 0; i < methodCount; i++) {
        Method method = methods[i];
        SEL selector = method_getName(method);
        NSString *methodName = NSStringFromSelector(selector);
        
        // Look for interesting methods
        if ([self isInterestingMethod:methodName]) {
            ZPLog(@"  Hooking method: %@ in %@", methodName, NSStringFromClass(cls));
            
            // In real implementation, would swizzle this method
            // [self swizzleMethod:selector inClass:cls];
        }
    }
    
    free(methods);
}

- (BOOL)isInterestingMethod:(NSString *)methodName {
    NSArray *patterns = @[
        @"token", @"Token", @"TOKEN",
        @"auth", @"Auth", @"AUTH",
        @"session", @"Session", @"SESSION",
        @"login", @"Login", @"LOGIN",
        @"credential", @"Credential"
    ];
    
    for (NSString *pattern in patterns) {
        if ([methodName containsString:pattern]) {
            return YES;
        }
    }
    return NO;
}

#pragma mark - Pitaya Classes

+ (void)hookPitayaClasses {
    ZPLog(@"Hooking Pitaya classes...");
    
    NSArray *pitayaClasses = @[
        @"Pitaya",
        @"PitayaClient",
        @"PitayaNetworkClient",
        @"PitayaSession",
        @"PitayaMessage"
    ];
    
    for (NSString *className in pitayaClasses) {
        Class cls = NSClassFromString(className);
        if (cls) {
            ZPLog(@"Found Pitaya class: %@", className);
            [self hookPitayaClass:cls];
        }
    }
}

+ (void)hookPitayaClass:(Class)cls {
    ZPLog(@"Hooking Pitaya class: %@", NSStringFromClass(cls));
    
    // Hook message sending methods
    // Hook message receiving methods
    // Hook connection methods
    
    // In real implementation:
    // - Hook sendMessage:
    // - Hook receiveMessage:
    // - Hook connect:
    // - Hook disconnect:
}

#pragma mark - Platform Classes

+ (void)hookPlatformClasses {
    ZPLog(@"Hooking Platform classes...");
    
    NSArray *platformClasses = @[
        @"PlatformPlayer",
        @"PlatformIdentification",
        @"PlatformNetworking",
        @"PlatformSession",
        @"WLNetworkClient",
        @"WLGameClient",
        @"WLAuthManager"
    ];
    
    for (NSString *className in platformClasses) {
        Class cls = NSClassFromString(className);
        if (cls) {
            ZPLog(@"Found Platform class: %@", className);
            [self hookClass:cls];
        }
    }
}

@end
