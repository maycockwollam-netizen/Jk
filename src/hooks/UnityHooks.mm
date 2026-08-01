//
//  UnityHooks.mm
//  ZoobaProto
//
//  Hooks for Unity classes
//

#import "UnityHooks.h"
#import "Config.h"
#import "StorageModule.h"

#define ZPLog(fmt, args...) NSLog(@"[ZoobaProto/Unity] " fmt, ##args)

@implementation UnityHooks

+ (void)install {
    ZPLog(@"Installing Unity hooks...");
    
    // Hook Unity Player
    [self hookUnityPlayer];
    
    // Hook PlayerPrefs
    [self hookUnityPlayerPrefs];
    
    // Hook Unity SendMessage
    [self hookUnitySendMessage];
    
    ZPLog(@"Unity hooks installed");
}

+ (void)uninstall {
    ZPLog(@"Uninstalling Unity hooks...");
}

#pragma mark - Unity Player

+ (void)hookUnityPlayer {
    ZPLog(@"Hooking UnityPlayer...");
    
    Class unityPlayerClass = NSClassFromString(@"UnityPlayer");
    if (unityPlayerClass) {
        ZPLog(@"Found UnityPlayer class!");
        
        // Hook UnityPlayer methods
        unsigned int methodCount = 0;
        Method *methods = class_copyMethodList(unityPlayerClass, &methodCount);
        
        if (methods) {
            for (unsigned int i = 0; i < methodCount; i++) {
                Method method = methods[i];
                SEL selector = method_getName(method);
                ZPLog(@"  UnityPlayer method: %@", NSStringFromSelector(selector));
            }
            free(methods);
        }
    } else {
        ZPLog(@"UnityPlayer class not found");
    }
}

#pragma mark - PlayerPrefs

+ (void)hookUnityPlayerPrefs {
    ZPLog(@"Hooking Unity PlayerPrefs...");
    
    // Unity stores PlayerPrefs in NSUserDefaults with specific keys
    // Hook GetString, SetString, etc.
    
    Class playerPrefsClass = NSClassFromString(@"PlayerPrefs");
    if (playerPrefsClass) {
        ZPLog(@"Found PlayerPrefs class!");
        
        // Hook GetString
        [self hookPlayerPrefsGetString:playerPrefsClass];
        
        // Hook SetString
        [self hookPlayerPrefsSetString:playerPrefsClass];
    } else {
        ZPLog(@"PlayerPrefs class not found");
        
        // Try alternative - Unity stores in NSUserDefaults
        [self hookUnityDefaults];
    }
}

+ (void)hookPlayerPrefsGetString:(Class)cls {
    // In real implementation, would swizzle:
    // +[PlayerPrefs GetString:]
    ZPLog(@"Would hook PlayerPrefs GetString:");
}

+ (void)hookPlayerPrefsSetString:(Class)cls {
    // In real implementation, would swizzle:
    // +[PlayerPrefs SetString:]
    ZPLog(@"Would hook PlayerPrefs SetString:");
}

+ (void)hookUnityDefaults {
    // Unity stores data in NSUserDefaults with these patterns:
    // - UnityPlayerPrefs
    // - unity.playerPrefs
    
    ZPLog(@"Hooking Unity NSUserDefaults...");
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *all = [defaults dictionaryRepresentation];
    
    ZPLog(@"Found %lu keys in NSUserDefaults", (unsigned long)all.count);
    
    // Scan for token-like keys
    for (NSString *key in all.allKeys) {
        NSString *lowercaseKey = [key lowercaseString];
        
        for (NSString *pattern in @[@"token", @"auth", @"session", @"player"]) {
            if ([lowercaseKey containsString:pattern]) {
                ZPLog(@"🎯 Token key found: %@", key);
                id value = all[key];
                if ([value isKindOfClass:[NSString class]]) {
                    ZPLog(@"  Value: %@", value);
                }
            }
        }
    }
}

#pragma mark - SendMessage

+ (void)hookUnitySendMessage {
    ZPLog(@"Hooking Unity SendMessage...");
    
    // Unity SendMessage is used for C# <-> ObjC communication
    // Note: UnityAppController not found in IPA v6.24.2
    // Using runtime discovery instead
    
    // Try to find Unity related classes
    NSArray *possibleClasses = @[
        @"UnityAppController",
        @"UnityController",
        @"MainAppController"
    ];
    
    for (NSString *className in possibleClasses) {
        Class unityClass = NSClassFromString(className);
        if (unityClass) {
            ZPLog(@"Found Unity class: %@", className);
            // Hook found class
            break;
        }
    }
    
    ZPLog(@"SendMessage hooks configured");
}

@end
