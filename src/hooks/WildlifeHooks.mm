//
//  WildlifeHooks.mm
//  ZoobaProto
//
//  Hooks for Wildlife Studios classes
//  Based on reverse-engineered Zooba code
//

#import "WildlifeHooks.h"
#import "Config.h"
#import "StorageModule.h"

#define ZPLog(fmt, args...) NSLog(@"[ZoobaProto/Wildlife] " fmt, ##args)

@implementation WildlifeHooks

+ (void)install {
    ZPLog(@"Installing Wildlife hooks...");
    ZPLog(@"Based on Wildlife.Platform.Core.dll analysis");
    
    // Hook Account Management
    [self hookAccountManager];
    
    // Hook Platform Networking (iOS binding)
    [self hookPlatformNetworking];
    
    // Hook Unity Bridge
    [self hookUnityBridge];
    
    // Hook Player Info
    [self hookPlayerInfo];
    
    // Hook Storage
    [self hookStorage];
    
    ZPLog(@"Wildlife hooks installed");
}

+ (void)uninstall {
    ZPLog(@"Uninstalling Wildlife hooks...");
}

#pragma mark - Account Management

+ (void)hookAccountManager {
    ZPLog(@"Hooking Wildlife Account Management...");
    
    // From Wildlife.Platform.Core.dll:
    // PlatformAccountManager class
    // - Account property (IPlayerAccount)
    // - SecurityToken property
    // - Authenticate()
    // - LoadCurrentAccount()
    
    NSArray *accountClasses = @[
        @"PlatformAccountManager",
        @"AccountManager",
        @"WLAuthManager",
        @"WLAccountManager"
    ];
    
    for (NSString *className in accountClasses) {
        Class cls = NSClassFromString(className);
        if (cls) {
            ZPLog(@"Found Account class: %@", className);
            [self hookAccountClass:cls];
        }
    }
}

+ (void)hookAccountClass:(Class)cls {
    // Key methods to hook:
    // - get_Account / set_Account
    // - get_SecurityToken / set_SecurityToken
    // - Authenticate
    // - LoadCurrentAccount
    // - CreateOrAuthenticate
    
    unsigned int methodCount = 0;
    Method *methods = class_copyMethodList(cls, &methodCount);
    
    for (unsigned int i = 0; i < methodCount; i++) {
        Method method = methods[i];
        SEL selector = method_getName(method);
        NSString *methodName = NSStringFromSelector(selector);
        
        // Hook token-related methods
        if ([self isTokenMethod:methodName]) {
            ZPLog(@"  🎯 HOOKING: %@ in %@", methodName, NSStringFromClass(cls));
            // Would swizzle here
        }
    }
    
    free(methods);
}

#pragma mark - Platform Networking

+ (void)hookPlatformNetworking {
    ZPLog(@"Hooking Platform Networking...");
    
    // From Wildlife.Platform.Core.dll:
    // PlatformNetworking (C#) -> PlatformNetworkingIOSBinding (ObjC)
    // - SendRequest
    // - SetPlatformHeader
    // - GetPlatformHeaders
    // - OnRequest event
    
    NSArray *networkClasses = @[
        @"PlatformNetworkingIOSBinding",
        @"PlatformNetworking",
        @"WLNetworkClient",
        @"WLNetworking",
        @"WildlifeNetworking"
    ];
    
    for (NSString *className in networkClasses) {
        Class cls = NSClassFromString(className);
        if (cls) {
            ZPLog(@"Found Network class: %@", className);
            [self hookNetworkClass:cls];
        }
    }
}

+ (void)hookNetworkClass:(Class)cls {
    unsigned int methodCount = 0;
    Method *methods = class_copyMethodList(cls, &methodCount);
    
    for (unsigned int i = 0; i < methodCount; i++) {
        Method method = methods[i];
        SEL selector = method_getName(method);
        NSString *methodName = NSStringFromSelector(selector);
        
        // Hook request/response methods
        if ([self isNetworkMethod:methodName]) {
            ZPLog(@"  🎯 HOOKING: %@", methodName);
            // Would swizzle here
        }
    }
    
    free(methods);
}

#pragma mark - Unity Bridge

+ (void)hookUnityBridge {
    ZPLog(@"Hooking Unity Bridge...");
    
    // UnityWebRequestBridge connects ObjC to Unity
    NSArray *bridgeClasses = @[
        @"UnityWebRequestBridge",
        @"UnityBridge",
        @"WLBridge"
    ];
    
    for (NSString *className in bridgeClasses) {
        Class cls = NSClassFromString(className);
        if (cls) {
            ZPLog(@"Found Bridge class: %@", className);
            [self hookBridgeClass:cls];
        }
    }
}

+ (void)hookBridgeClass:(Class)cls {
    unsigned int methodCount = 0;
    Method *methods = class_copyMethodList(cls, &methodCount);
    
    for (unsigned int i = 0; i < methodCount; i++) {
        Method method = methods[i];
        SEL selector = method_getName(method);
        NSString *methodName = NSStringFromSelector(selector);
        ZPLog(@"  Bridge method: %@", methodName);
    }
    
    free(methods);
}

#pragma mark - Player Info

+ (void)hookPlayerInfo {
    ZPLog(@"Hooking Player Info...");
    
    // From Wildlife.Platform.Core.dll:
    // PlayerAccount class:
    // - Id (Player ID)
    // - SecurityToken (JWT)
    // - TenantId
    // - AccountData
    
    NSArray *playerClasses = @[
        @"PlayerAccount",
        @"PlatformPlayer",
        @"WLPlayer"
    ];
    
    for (NSString *className in playerClasses) {
        Class cls = NSClassFromString(className);
        if (cls) {
            ZPLog(@"Found Player class: %@", className);
            [self hookPlayerClass:cls];
        }
    }
}

+ (void)hookPlayerClass:(Class)cls {
    unsigned int methodCount = 0;
    Method *methods = class_copyMethodList(cls, &methodCount);
    
    for (unsigned int i = 0; i < methodCount; i++) {
        Method method = methods[i];
        SEL selector = method_getName(method);
        NSString *methodName = NSStringFromSelector(selector);
        
        if ([self isTokenMethod:methodName] || 
            [methodName containsString:@"Player"] ||
            [methodName containsString:@"Id"]) {
            ZPLog(@"  🎯 PLAYER: %@", methodName);
            // Would hook
        }
    }
    
    free(methods);
}

#pragma mark - Storage

+ (void)hookStorage {
    ZPLog(@"Hooking Storage...");
    
    // Hook PlayerPrefs access
    // From Wildlife.Persistency.dll
}

#pragma mark - Method Detection

+ (BOOL)isTokenMethod:(NSString *)methodName {
    NSArray *patterns = @[
        @"SecurityToken",
        @"get_SecurityToken",
        @"set_SecurityToken",
        @"Token",
        @"get_Token",
        @"Auth",
        @"Account",
        @"Bearer",
        @"Authorization"
    ];
    
    for (NSString *pattern in patterns) {
        if ([methodName containsString:pattern]) {
            return YES;
        }
    }
    return NO;
}

+ (BOOL)isNetworkMethod:(NSString *)methodName {
    NSArray *patterns = @[
        @"SendRequest",
        @"SetHeader",
        @"AddHeader",
        @"GetHeaders",
        @"GetPlatformHeaders",
        @"Request",
        @"Response",
        @"Send"
    ];
    
    for (NSString *pattern in patterns) {
        if ([methodName containsString:pattern]) {
            return YES;
        }
    }
    return NO;
}

@end
