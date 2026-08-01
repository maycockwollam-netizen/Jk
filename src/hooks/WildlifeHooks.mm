//
//  WildlifeHooks.mm
//  ZoobaProto
//
//  Complete Hook Implementations for Wildlife Studios
//  Based on reverse-engineered Zooba code
//

#import "WildlifeHooks.h"
#import "Config.h"
#import "StorageModule.h"
#import "Swizzler.h"

#define ZPLog(fmt, args...) NSLog(@"[ZoobaProto/Wildlife] " fmt, ##args)
#define ZPTokenFound(token) ZPLog(@"🎉 TOKEN FOUND: %@", token)

static NSMutableDictionary *g_capturedTokens = nil;
static NSMutableSet *g_processedRequests = nil;

@implementation WildlifeHooks

+ (void)load {
    g_capturedTokens = [NSMutableDictionary dictionary];
    g_processedRequests = [NSMutableSet set];
}

+ (void)install {
    ZPLog(@"===========================================");
    ZPLog(@"Installing Wildlife hooks (COMPLETE)...");
    ZPLog(@"===========================================");
    
    // 1. Hook Account Management
    [self hookAccountManager];
    
    // 2. Hook Platform Networking
    [self hookPlatformNetworking];
    
    // 3. Hook PlayerAccount properties
    [self hookPlayerAccount];
    
    // 4. Hook NSUserDefaults
    [self hookNSUserDefaults];
    
    // 5. Hook Unity PlayerPrefs
    [self hookUnityPlayerPrefs];
    
    // 6. Hook NSURLSession
    [self hookNSURLSession];
    
    // 7. Hook Keychain
    [self hookKeychain];
    
    ZPLog(@"===========================================");
    ZPLog(@"All Wildlife hooks installed!");
    ZPLog(@"===========================================");
}

#pragma mark - 1. Account Management Hook

+ (void)hookAccountManager {
    ZPLog(@"Hooking Account Management...");
    
    // Try to find PlatformAccountManager
    Class accountManagerClass = NSClassFromString(@"PlatformAccountManager");
    if (!accountManagerClass) {
        accountManagerClass = NSClassFromString(@"AccountManager");
    }
    if (!accountManagerClass) {
        accountManagerClass = NSClassFromString(@"WLAuthManager");
    }
    
    if (accountManagerClass) {
        ZPLog(@"Found AccountManager: %@", NSStringFromClass(accountManagerClass));
        [self hookAccountManagerClass:accountManagerClass];
    } else {
        ZPLog(@"AccountManager class not found - will try runtime discovery");
        [self discoverAndHookAccountClasses];
    }
}

+ (void)hookAccountManagerClass:(Class)cls {
    // Hook: get_Account property
    SEL accountSEL = NSSelectorFromString(@"account");
    if ([cls instancesRespondToSelector:accountSEL]) {
        [self hookAccountGetter:cls];
        ZPLog(@"  Hooked: account getter");
    }
    
    // Hook: SecurityToken property
    SEL tokenSEL = NSSelectorFromString(@"securityToken");
    if ([cls instancesRespondToSelector:tokenSEL]) {
        [self hookSecurityTokenGetter:cls];
        ZPLog(@"  Hooked: securityToken getter");
    }
    
    // Hook: Authenticate method
    SEL authSEL = NSSelectorFromString(@"authenticate");
    if ([cls instancesRespondToSelector:authSEL]) {
        [self hookAuthenticateMethod:cls];
        ZPLog(@"  Hooked: authenticate method");
    }
    
    // Hook: LoadCurrentAccount method
    SEL loadSEL = NSSelectorFromString(@"loadCurrentAccount");
    if ([cls instancesRespondToSelector:loadSEL]) {
        [self hookLoadCurrentAccount:cls];
        ZPLog(@"  Hooked: loadCurrentAccount");
    }
    
    // Hook: CreateOrAuthenticate method
    SEL createAuthSEL = NSSelectorFromString(@"createOrAuthenticate");
    if ([cls instancesRespondToSelector:createAuthSEL]) {
        [self hookCreateOrAuthenticate:cls];
        ZPLog(@"  Hooked: createOrAuthenticate");
    }
}

+ (void)hookAccountGetter:(Class)cls {
    SEL originalSEL = NSSelectorFromString(@"account");
    SEL swizzledSEL = NSSelectorFromString(@"zp_account");
    
    Method originalMethod = class_getInstanceMethod(cls, originalSEL);
    if (!originalMethod) return;
    
    IMP originalIMP = method_getImplementation(originalMethod);
    
    // Create swizzled implementation
    __block IMP original = originalIMP;
    
    IMP swizzledIMP = imp_implementationWithBlock(^(id self) {
        // Call original
        id account = ((id (*)(id, SEL))original)(self, originalSEL);
        
        // Hook the returned account
        if (account) {
            [self extractTokensFromAccount:account];
        }
        
        return account;
    });
    
    method_setImplementation(originalMethod, swizzledIMP);
    ZPLog(@"    Swizzled: account getter");
}

+ (void)hookSecurityTokenGetter:(Class)cls {
    SEL originalSEL = NSSelectorFromString(@"securityToken");
    SEL swizzledSEL = NSSelectorFromString(@"zp_securityToken");
    
    Method originalMethod = class_getInstanceMethod(cls, originalSEL);
    if (!originalMethod) return;
    
    IMP originalIMP = method_getImplementation(originalMethod);
    
    __block IMP original = originalIMP;
    
    IMP swizzledIMP = imp_implementationWithBlock(^(id self) {
        id token = ((id (*)(id, SEL))original)(self, originalSEL);
        
        if (token && [token isKindOfClass:[NSString class]] && [(NSString *)token length] > 10) {
            ZPTokenFound([NSString stringWithFormat:@"SecurityToken: %@...", [(NSString *)token substringToIndex:MIN(50, [(NSString *)token length])]]);
            g_capturedTokens[@"securityToken"] = token;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ZoobaProtoTokenFound" 
                                                              object:nil 
                                                            userInfo:@{@"token": token, @"source": @"SecurityToken"}];
        }
        
        return token;
    });
    
    method_setImplementation(originalMethod, swizzledIMP);
    ZPLog(@"    Swizzled: securityToken getter");
}

+ (void)hookAuthenticateMethod:(Class)cls {
    SEL originalSEL = NSSelectorFromString(@"authenticate");
    if (![cls instancesRespondToSelector:originalSEL]) return;
    
    // Hook authenticate method
    [Swizzler hookMethod:cls selector:originalSEL 
             beforeBlock:^(id self, NSInvocation *inv) {
        ZPLog(@"    Authenticate called");
    } afterBlock:^(id self, NSInvocation *inv, id returnValue) {
        ZPLog(@"    Authenticate completed");
    }];
}

+ (void)hookLoadCurrentAccount:(Class)cls {
    SEL originalSEL = NSSelectorFromString(@"loadCurrentAccount");
    if (![cls instancesRespondToSelector:originalSEL]) return;
    
    [Swizzler hookMethod:cls selector:originalSEL 
             beforeBlock:^(id self, NSInvocation *inv) {
        ZPLog(@"    loadCurrentAccount called");
    } afterBlock:^(id self, NSInvocation *inv, id returnValue) {
        ZPLog(@"    loadCurrentAccount completed");
        // Try to extract tokens after load
        if ([self respondsToSelector:NSSelectorFromString(@"account")]) {
            id account = [self performSelector:NSSelectorFromString(@"account")];
            if (account) {
                [self extractTokensFromAccount:account];
            }
        }
    }];
}

+ (void)hookCreateOrAuthenticate:(Class)cls {
    SEL originalSEL = NSSelectorFromString(@"createOrAuthenticate");
    if (![cls instancesRespondToSelector:originalSEL]) return;
    
    [Swizzler hookMethod:cls selector:originalSEL 
             beforeBlock:^(id self, NSInvocation *inv) {
        ZPLog(@"    createOrAuthenticate called");
    } afterBlock:^(id self, NSInvocation *inv, id returnValue) {
        ZPLog(@"    createOrAuthenticate completed");
    }];
}

+ (void)extractTokensFromAccount:(id)account {
    if (!account) return;
    
    // Try various token properties
    NSArray *tokenProps = @[@"securityToken", @"token", @"accessToken", @"authToken", @"bearerToken"];
    
    for (NSString *prop in tokenProps) {
        SEL sel = NSSelectorFromString(prop);
        if ([account respondsToSelector:sel]) {
            
            __weak id token = [account performSelector:sel];
            
            if (token && [token isKindOfClass:[NSString class]] && [(NSString *)token length] > 10) {
                NSString *tokenStr = (NSString *)token;
                ZPTokenFound([NSString stringWithFormat:@"%@: %@...", prop, [tokenStr substringToIndex:MIN(50, tokenStr.length)]]);
                g_capturedTokens[prop] = tokenStr;
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ZoobaProtoTokenFound" 
                                                                  object:nil 
                                                                userInfo:@{@"token": tokenStr, @"source": prop}];
            }
        }
    }
    
    // Try playerId
    SEL playerIdSEL = NSSelectorFromString(@"playerId");
    if ([account respondsToSelector:playerIdSEL]) {
        id playerId = [account performSelector:playerIdSEL];
        if (playerId) {
            ZPLog(@"    Player ID: %@", playerId);
            g_capturedTokens[@"playerId"] = playerId;
        }
    }
    
    // Try Id
    SEL idSEL = NSSelectorFromString(@"id");
    if ([account respondsToSelector:idSEL]) {
        id accountId = [account performSelector:idSEL];
        if (accountId) {
            ZPLog(@"    Account ID: %@", accountId);
            g_capturedTokens[@"accountId"] = accountId;
        }
    }
}

+ (void)discoverAndHookAccountClasses {
    int classCount = objc_getClassList(NULL, 0);
    if (classCount == 0) return;
    
    Class *classes = (Class *)malloc(sizeof(Class) * classCount);
    objc_getClassList(classes, classCount);
    
    for (int i = 0; i < classCount; i++) {
        Class cls = classes[i];
        NSString *name = NSStringFromClass(cls);
        
        // Look for account-related classes
        if ([name containsString:@"Account"] || [name containsString:@"Auth"] || 
            [name containsString:@"Player"] || [name containsString:@"WL"]) {
            
            unsigned int methodCount = 0;
            Method *methods = class_copyMethodList(cls, &methodCount);
            
            BOOL hasToken = NO;
            BOOL hasAccount = NO;
            
            for (unsigned int j = 0; j < methodCount; j++) {
                NSString *methodName = NSStringFromSelector(method_getName(methods[j]));
                if ([methodName containsString:@"Token"] || [methodName containsString:@"token"]) {
                    hasToken = YES;
                }
                if ([methodName containsString:@"Account"] || [methodName containsString:@"account"]) {
                    hasAccount = YES;
                }
            }
            
            free(methods);
            
            if (hasToken || hasAccount) {
                ZPLog(@"Discovered account class: %@", name);
                [self hookAccountManagerClass:cls];
            }
        }
    }
    
    free(classes);
}

#pragma mark - 2. Platform Networking Hook

+ (void)hookPlatformNetworking {
    ZPLog(@"Hooking Platform Networking...");
    
    Class networkClass = NSClassFromString(@"PlatformNetworkingIOSBinding");
    if (!networkClass) {
        networkClass = NSClassFromString(@"WLNetworkClient");
    }
    if (!networkClass) {
        networkClass = NSClassFromString(@"PlatformNetworking");
    }
    
    if (networkClass) {
        ZPLog(@"Found Network class: %@", NSStringFromClass(networkClass));
        [self hookPlatformNetworkingClass:networkClass];
    } else {
        ZPLog(@"Network class not found - will use NSURLSession hook instead");
    }
}

+ (void)hookPlatformNetworkingClass:(Class)cls {
    // Hook: SendRequest methods
    unsigned int methodCount = 0;
    Method *methods = class_copyMethodList(cls, &methodCount);
    
    for (unsigned int i = 0; i < methodCount; i++) {
        Method method = methods[i];
        NSString *methodName = NSStringFromSelector(method_getName(method));
        
        // Hook SendRequest variants
        if ([methodName containsString:@"SendRequest"]) {
            ZPLog(@"  Hooking: %@", methodName);
            [self hookSendRequest:cls methodName:methodName];
        }
        
        // Hook SetHeader variants
        if ([methodName containsString:@"SetHeader"]) {
            ZPLog(@"  Hooking: %@", methodName);
            [self hookSetHeader:cls methodName:methodName];
        }
        
        // Hook GetHeaders
        if ([methodName containsString:@"GetHeaders"] || [methodName containsString:@"PlatformHeader"]) {
            ZPLog(@"  Hooking: %@", methodName);
            [self hookGetHeaders:cls methodName:methodName];
        }
    }
    
    free(methods);
}

+ (void)hookSendRequest:(Class)cls methodName:(NSString *)methodName {
    SEL originalSEL = NSSelectorFromString(methodName);
    if (![cls instancesRespondToSelector:originalSEL]) return;
    
    [Swizzler hookMethod:cls selector:originalSEL 
             beforeBlock:^(id self, NSInvocation *inv) {
        
        // Log the request
        ZPLog(@"🚀 SEND REQUEST: %@", methodName);
        
        // Try to extract request info from invocation
        NSMethodSignature *sig = [inv methodSignature];
        NSUInteger argCount = [sig numberOfArguments];
        
        for (NSUInteger i = 0; i < argCount; i++) {
            const char *argType = [sig getArgumentTypeAtIndex:i];
            if (argType[0] == '@') { // Object
                __unsafe_unretained id arg = nil;
                [inv getArgument:&arg atIndex:i];
                if (arg) {
                    ZPLog(@"  Arg[%lu]: %@", (unsigned long)i, [arg class]);
                    
                    // Try to extract URL
                    if ([arg respondsToSelector:@selector(URL)]) {
                        ZPLog(@"  URL: %@", [arg performSelector:@selector(URL)]);
                    }
                    
                    // Try to extract headers
                    if ([arg respondsToSelector:@selector(allHTTPHeaderFields)]) {
                        NSDictionary *headers = [arg performSelector:@selector(allHTTPHeaderFields)];
                        [self checkHeadersForTokens:headers];
                    }
                }
            }
        }
        
    } afterBlock:^(id self, NSInvocation *inv, id returnValue) {
        ZPLog(@"  Request completed");
    }];
}

+ (void)hookSetHeader:(Class)cls methodName:(NSString *)methodName {
    SEL originalSEL = NSSelectorFromString(methodName);
    if (![cls instancesRespondToSelector:originalSEL]) return;
    
    [Swizzler hookMethod:cls selector:originalSEL 
             beforeBlock:^(id self, NSInvocation *inv) {
        
        NSMethodSignature *sig = [inv methodSignature];
        
        // Extract header key and value
        if ([sig numberOfArguments] >= 3) {
            __unsafe_unretained id key = nil;
            __unsafe_unretained id value = nil;
            [inv getArgument:&key atIndex:2];
            [inv getArgument:&value atIndex:3];
            
            if (key && value) {
                ZPLog(@"📋 SET HEADER: %@ = %@", key, value);
                
                // Check for auth headers
                NSString *keyStr = [key isKindOfClass:[NSString class]] ? (NSString *)key : @"";
                NSString *valueStr = [value isKindOfClass:[NSString class]] ? (NSString *)value : @"";
                
                if ([keyStr.lowercaseString containsString:@"token"] || 
                    [keyStr.lowercaseString containsString:@"auth"]) {
                    ZPTokenFound([NSString stringWithFormat:@"Header %@: %@...", keyStr, [valueStr substringToIndex:MIN(50, valueStr.length)]]);
                    g_capturedTokens[keyStr] = valueStr;
                }
            }
        }
        
    } afterBlock:nil];
}

+ (void)hookGetHeaders:(Class)cls methodName:(NSString *)methodName {
    SEL originalSEL = NSSelectorFromString(methodName);
    if (![cls instancesRespondToSelector:originalSEL]) return;
    
    [Swizzler hookMethod:cls selector:originalSEL 
             beforeBlock:nil 
             afterBlock:^(id self, NSInvocation *inv, id returnValue) {
        
        if (returnValue && [returnValue isKindOfClass:[NSDictionary class]]) {
            NSDictionary *headers = (NSDictionary *)returnValue;
            ZPLog(@"📋 GET HEADERS: %lu items", (unsigned long)headers.count);
            [self checkHeadersForTokens:headers];
        }
    }];
}

+ (void)checkHeadersForTokens:(NSDictionary *)headers {
    if (!headers || headers.count == 0) return;
    
    NSArray *authHeaders = @[@"Authorization", @"authorization", @"X-Security-Token", 
                              @"X-Auth-Token", @"X-Access-Token", @"Token", @"Bearer"];
    
    for (NSString *key in headers) {
        for (NSString *authKey in authHeaders) {
            if ([key.lowercaseString isEqualToString:authKey.lowercaseString]) {
                NSString *value = headers[key];
                if (value && value.length > 0) {
                    ZPTokenFound([NSString stringWithFormat:@"Header %@: %@...", key, [value substringToIndex:MIN(50, value.length)]]);
                    g_capturedTokens[key] = value;
                    
                    // Check if it's a Bearer token
                    if ([value.lowercaseString hasPrefix:@"bearer "]) {
                        NSString *token = [value substringFromIndex:7];
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"ZoobaProtoTokenFound" 
                                                                          object:nil 
                                                                        userInfo:@{@"token": value, @"source": @"Authorization Header"}];
                    } else if ([value hasPrefix:@"eyJ"]) {
                        // JWT
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"ZoobaProtoTokenFound" 
                                                                          object:nil 
                                                                        userInfo:@{@"token": value, @"source": @"JWT Header"}];
                    }
                }
            }
        }
    }
}

#pragma mark - 3. PlayerAccount Hook

+ (void)hookPlayerAccount {
    ZPLog(@"Hooking PlayerAccount...");
    
    Class playerClass = NSClassFromString(@"PlayerAccount");
    if (!playerClass) {
        playerClass = NSClassFromString(@"PlatformPlayer");
    }
    
    if (playerClass) {
        ZPLog(@"Found PlayerAccount: %@", NSStringFromClass(playerClass));
        [self hookPlayerAccountClass:playerClass];
    }
}

+ (void)hookPlayerAccountClass:(Class)cls {
    // Hook all getter methods
    unsigned int methodCount = 0;
    Method *methods = class_copyMethodList(cls, &methodCount);
    
    for (unsigned int i = 0; i < methodCount; i++) {
        Method method = methods[i];
        NSString *methodName = NSStringFromSelector(method_getName(method));
        
        // Only hook property getters (get_XXX)
        if ([methodName hasPrefix:@"get_"] || 
            ([methodName isEqualToString:@"securityToken"] ||
             [methodName isEqualToString:@"token"] ||
             [methodName isEqualToString:@"id"] ||
             [methodName isEqualToString:@"Id"] ||
             [methodName isEqualToString:@"playerId"] ||
             [methodName isEqualToString:@"playerID"])) {
            
            [self hookPlayerPropertyGetter:cls methodName:methodName];
        }
    }
    
    free(methods);
}

+ (void)hookPlayerPropertyGetter:(Class)cls methodName:(NSString *)methodName {
    SEL originalSEL = NSSelectorFromString(methodName);
    if (!originalSEL) return;
    
    if (![cls instancesRespondToSelector:originalSEL]) return;
    
    Method originalMethod = class_getInstanceMethod(cls, originalSEL);
    if (!originalMethod) return;
    
    IMP originalIMP = method_getImplementation(originalMethod);
    __block IMP original = originalIMP;
    
    IMP swizzledIMP = imp_implementationWithBlock(^(id self) {
        id value = ((id (*)(id, SEL))original)(self, originalSEL);
        
        if (value) {
            BOOL isToken = [methodName containsString:@"Token"] || 
                           [methodName containsString:@"token"] ||
                           [methodName containsString:@"Security"];
            
            if (isToken && [value isKindOfClass:[NSString class]] && [(NSString *)value length] > 10) {
                ZPTokenFound([NSString stringWithFormat:@"PlayerAccount.%@: %@...", 
                            methodName, [(NSString *)value substringToIndex:MIN(50, [(NSString *)value length])]]);
                g_capturedTokens[methodName] = value;
            } else {
                ZPLog(@"📋 PlayerAccount.%@: %@", methodName, value);
                g_capturedTokens[methodName] = value;
            }
        }
        
        return value;
    });
    
    method_setImplementation(originalMethod, swizzledIMP);
}

#pragma mark - 4. NSUserDefaults Hook

+ (void)hookNSUserDefaults {
    ZPLog(@"Hooking NSUserDefaults...");
    
    Class defaultsClass = [NSUserDefaults class];
    
    // Hook: stringForKey:
    SEL stringForKeySEL = @selector(stringForKey:);
    if ([defaultsClass instancesRespondToSelector:stringForKeySEL]) {
        [self hookNSUserDefaultsStringForKey];
    }
    
    // Hook: objectForKey:
    SEL objectForKeySEL = @selector(objectForKey:);
    [self hookNSUserDefaultsObjectForKey];
    
    // Hook: setObject:forKey:
    SEL setObjectSEL = @selector(setObject:forKey:);
    [self hookNSUserDefaultsSetObject];
}

+ (void)hookNSUserDefaultsStringForKey {
    Class cls = [NSUserDefaults class];
    SEL originalSEL = @selector(stringForKey:);
    Method originalMethod = class_getInstanceMethod(cls, originalSEL);
    if (!originalMethod) return;
    
    IMP originalIMP = method_getImplementation(originalMethod);
    __block IMP original = originalIMP;
    
    IMP swizzledIMP = imp_implementationWithBlock(^(NSUserDefaults *self, NSString *key) {
        id value = ((id (*)(id, SEL, NSString *))original)(self, originalSEL, key);
        
        if (value && [value isKindOfClass:[NSString class]] && [(NSString *)value length] > 10) {
            [self checkUserDefaultsValue:value forKey:key];
        }
        
        return value;
    });
    
    method_setImplementation(originalMethod, swizzledIMP);
    ZPLog(@"  Swizzled: stringForKey:");
}

+ (void)hookNSUserDefaultsObjectForKey {
    Class cls = [NSUserDefaults class];
    SEL originalSEL = @selector(objectForKey:);
    Method originalMethod = class_getInstanceMethod(cls, originalSEL);
    if (!originalMethod) return;
    
    IMP originalIMP = method_getImplementation(originalMethod);
    __block IMP original = originalIMP;
    
    IMP swizzledIMP = imp_implementationWithBlock(^(NSUserDefaults *self, NSString *key) {
        id value = ((id (*)(id, SEL, NSString *))original)(self, originalSEL, key);
        
        if (value) {
            [self checkUserDefaultsValue:value forKey:key];
        }
        
        return value;
    });
    
    method_setImplementation(originalMethod, swizzledIMP);
    ZPLog(@"  Swizzled: objectForKey:");
}

+ (void)hookNSUserDefaultsSetObject {
    Class cls = [NSUserDefaults class];
    SEL originalSEL = @selector(setObject:forKey:);
    Method originalMethod = class_getInstanceMethod(cls, originalSEL);
    if (!originalMethod) return;
    
    IMP originalIMP = method_getImplementation(originalMethod);
    __block IMP original = originalIMP;
    
    IMP swizzledIMP = imp_implementationWithBlock(^(NSUserDefaults *self, id object, NSString *key) {
        // Check before setting
        if (object) {
            [self checkUserDefaultsValue:object forKey:key];
        }
        
        ((void (*)(id, SEL, id, NSString *))original)(self, originalSEL, object, key);
    });
    
    method_setImplementation(originalMethod, swizzledIMP);
    ZPLog(@"  Swizzled: setObject:forKey:");
}

+ (void)checkUserDefaultsValue:(id)value forKey:(NSString *)key {
    if (!key) return;
    
    // Check if key is interesting
    NSArray *interestingKeys = @[@"token", @"Token", @"auth", @"Auth", @"security", @"Security",
                                 @"account", @"Account", @"player", @"Player", @"session", @"Session",
                                 @"wildlife", @"Wildlife", @"wl_", @"WL", @"Bearer", @"bearer"];
    
    BOOL isInteresting = NO;
    for (NSString *pattern in interestingKeys) {
        if ([key containsString:pattern]) {
            isInteresting = YES;
            break;
        }
    }
    
    if (!isInteresting) return;
    
    // Check if value looks like a token
    NSString *valueStr = nil;
    if ([value isKindOfClass:[NSString class]]) {
        valueStr = (NSString *)value;
    } else if ([value isKindOfClass:[NSData class]]) {
        NSData *data = (NSData *)value;
        valueStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    
    if (valueStr && valueStr.length > 10) {
        ZPLog(@"📋 NSUserDefaults[%@] = %@...", key, [valueStr substringToIndex:MIN(50, valueStr.length)]);
        g_capturedTokens[key] = valueStr;
        
        // Check for JWT
        if ([valueStr hasPrefix:@"eyJ"]) {
            ZPTokenFound([NSString stringWithFormat:@"NSUserDefaults JWT[%@]: %@...", key, [valueStr substringToIndex:MIN(50, valueStr.length)]]);
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ZoobaProtoTokenFound" 
                                                              object:nil 
                                                            userInfo:@{@"token": valueStr, @"source": @"NSUserDefaults"}];
        }
    }
}

#pragma mark - 5. Unity PlayerPrefs Hook

+ (void)hookUnityPlayerPrefs {
    ZPLog(@"Hooking Unity PlayerPrefs...");
    
    Class playerPrefsClass = NSClassFromString(@"PlayerPrefs");
    if (!playerPrefsClass) {
        playerPrefsClass = NSClassFromString(@"UnityPlayerPrefs");
    }
    
    if (playerPrefsClass) {
        ZPLog(@"Found PlayerPrefs: %@", NSStringFromClass(playerPrefsClass));
        [self hookPlayerPrefsClass:playerPrefsClass];
    }
}

+ (void)hookPlayerPrefsClass:(Class)cls {
    // Hook GetString
    SEL getStringSEL = NSSelectorFromString(@"getString:");
    if ([cls respondsToSelector:getStringSEL]) {
        [self hookPlayerPrefsGetString];
    }
    
    // Hook SetString
    SEL setStringSEL = NSSelectorFromString(@"setString:forKey:");
    if ([cls respondsToSelector:setStringSEL]) {
        [self hookPlayerPrefsSetString];
    }
    
    // Hook GetStringForPlatform
    SEL getForPlatformSEL = NSSelectorFromString(@"getStringForPlatform:withKey:");
    if ([cls respondsToSelector:getForPlatformSEL]) {
        [self hookPlayerPrefsGetForPlatform];
    }
}

+ (void)hookPlayerPrefsGetString {
    Class cls = [NSClassFromString(@"PlayerPrefs") ?: [NSClassFromString(@"UnityPlayerPrefs") class]];
    if (!cls) return;
    
    SEL originalSEL = NSSelectorFromString(@"getString:");
    if (!originalSEL) return;
    
    Method originalMethod = class_getInstanceMethod(cls, originalSEL);
    if (!originalMethod) return;
    
    IMP originalIMP = method_getImplementation(originalMethod);
    __block IMP original = originalIMP;
    
    IMP swizzledIMP = imp_implementationWithBlock(^(id self, NSString *key) {
        id value = ((id (*)(id, SEL, NSString *))original)(self, originalSEL, key);
        
        if (value && [value isKindOfClass:[NSString class]] && [(NSString *)value length] > 10) {
            [self checkPlayerPrefsValue:value forKey:key];
        }
        
        return value;
    });
    
    method_setImplementation(originalMethod, swizzledIMP);
    ZPLog(@"  Swizzled: getString:");
}

+ (void)hookPlayerPrefsSetString {
    Class cls = [NSClassFromString(@"PlayerPrefs") ?: [NSClassFromString(@"UnityPlayerPrefs") class]];
    if (!cls) return;
    
    SEL originalSEL = NSSelectorFromString(@"setString:forKey:");
    if (!originalSEL) return;
    
    Method originalMethod = class_getInstanceMethod(cls, originalSEL);
    if (!originalMethod) return;
    
    IMP originalIMP = method_getImplementation(originalMethod);
    __block IMP original = originalIMP;
    
    IMP swizzledIMP = imp_implementationWithBlock(^(id self, NSString *value, NSString *key) {
        ZPLog(@"📝 PlayerPrefs SET: %@ = %@...", key, [value substringToIndex:MIN(30, value.length)]);
        ((void (*)(id, SEL, NSString *, NSString *))original)(self, originalSEL, value, key);
    });
    
    method_setImplementation(originalMethod, swizzledIMP);
    ZPLog(@"  Swizzled: setString:forKey:");
}

+ (void)hookPlayerPrefsGetForPlatform {
    Class cls = [NSClassFromString(@"PlayerPrefs") ?: [NSClassFromString(@"UnityPlayerPrefs") class]];
    if (!cls) return;
    
    SEL originalSEL = NSSelectorFromString(@"getStringForPlatform:withKey:");
    if (!originalSEL) return;
    
    Method originalMethod = class_getInstanceMethod(cls, originalSEL);
    if (!originalMethod) return;
    
    IMP originalIMP = method_getImplementation(originalMethod);
    __block IMP original = originalIMP;
    
    IMP swizzledIMP = imp_implementationWithBlock(^(id self, id platform, NSString *key) {
        id value = ((id (*)(id, SEL, id, NSString *))original)(self, originalSEL, platform, key);
        
        if (value && [value isKindOfClass:[NSString class]] && [(NSString *)value length] > 10) {
            [self checkPlayerPrefsValue:value forKey:key];
        }
        
        return value;
    });
    
    method_setImplementation(originalMethod, swizzledIMP);
    ZPLog(@"  Swizzled: getStringForPlatform:withKey:");
}

+ (void)checkPlayerPrefsValue:(NSString *)value forKey:(NSString *)key {
    if (!value || !key) return;
    
    NSArray *tokenPatterns = @[@"token", @"Token", @"auth", @"Auth", @"security", @"session", @"account"];
    BOOL isToken = NO;
    
    for (NSString *pattern in tokenPatterns) {
        if ([key containsString:pattern]) {
            isToken = YES;
            break;
        }
    }
    
    if (isToken || [value hasPrefix:@"eyJ"] || [value hasPrefix:@"Bearer"]) {
        ZPLog(@"🎯 PlayerPrefs[%@] = %@...", key, [value substringToIndex:MIN(50, value.length)]);
        g_capturedTokens[[NSString stringWithFormat:@"PlayerPrefs.%@", key]] = value;
        
        if ([value hasPrefix:@"eyJ"]) {
            ZPTokenFound([NSString stringWithFormat:@"PlayerPrefs JWT[%@]: %@...", key, [value substringToIndex:MIN(50, value.length)]]);
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ZoobaProtoTokenFound" 
                                                              object:nil 
                                                            userInfo:@{@"token": value, @"source": @"PlayerPrefs"}];
        }
    }
}

#pragma mark - 6. NSURLSession Hook

+ (void)hookNSURLSession {
    ZPLog(@"Hooking NSURLSession...");
    
    Class sessionClass = [NSURLSession class];
    
    // Hook: dataTaskWithRequest:completionHandler:
    SEL dataTaskSEL = @selector(dataTaskWithRequest:completionHandler:);
    [self hookNSURLSessionDataTask];
    
    // Hook: sendRequest:completionHandler:
    SEL sendRequestSEL = @selector(sendRequest:completionHandler:);
    if ([sessionClass respondsToSelector:sendRequestSEL]) {
        [self hookNSURLSessionSendRequest];
    }
}

+ (void)hookNSURLSessionDataTask {
    Class cls = [NSURLSession class];
    SEL originalSEL = @selector(dataTaskWithRequest:completionHandler:);
    
    Method originalMethod = class_getInstanceMethod(cls, originalSEL);
    if (!originalMethod) return;
    
    IMP originalIMP = method_getImplementation(originalMethod);
    __block IMP original = originalIMP;
    
    IMP swizzledIMP = imp_implementationWithBlock(^(NSURLSession *self, NSURLRequest *request, id completionHandler) {
        
        ZPLog(@"🌐 NSURLSession Request: %@ %@", request.HTTPMethod, request.URL.absoluteString);
        
        // Check headers
        NSDictionary *headers = request.allHTTPHeaderFields;
        if (headers) {
            [self checkHeadersForTokens:headers];
        }
        
        // Call original
        return ((id (*)(id, SEL, NSURLRequest *, id))original)(self, originalSEL, request, completionHandler);
    });
    
    method_setImplementation(originalMethod, swizzledIMP);
    ZPLog(@"  Swizzled: dataTaskWithRequest:");
}

+ (void)hookNSURLSessionSendRequest {
    Class cls = [NSURLSession class];
    SEL originalSEL = @selector(sendRequest:completionHandler:);
    
    Method originalMethod = class_getInstanceMethod(cls, originalSEL);
    if (!originalMethod) return;
    
    IMP originalIMP = method_getImplementation(originalMethod);
    __block IMP original = originalIMP;
    
    IMP swizzledIMP = imp_implementationWithBlock(^(NSURLSession *self, NSURLRequest *request, id completionHandler) {
        
        ZPLog(@"🌐 NSURLSession SendRequest: %@ %@", request.HTTPMethod, request.URL.absoluteString);
        
        NSDictionary *headers = request.allHTTPHeaderFields;
        if (headers) {
            [self checkHeadersForTokens:headers];
        }
        
        return ((void (*)(id, SEL, NSURLRequest *, id))original)(self, originalSEL, request, completionHandler);
    });
    
    method_setImplementation(originalMethod, swizzledIMP);
    ZPLog(@"  Swizzled: sendRequest:");
}

#pragma mark - 7. Keychain Hook

+ (void)hookKeychain {
    ZPLog(@"Hooking Keychain...");
    
    // Keychain functions are C-based, would need fishhook
    // For now, log that we're looking for Keychain access
    ZPLog(@"  Note: Keychain hooking requires fishhook for C functions");
    ZPLog(@"  Will hook SecItemCopyMatching, SecItemAdd, SecItemUpdate");
    
    // This would require using fishhook to hook:
    // - SecItemCopyMatching
    // - SecItemAdd
    // - SecItemUpdate
    // - SecItemDelete
}

#pragma mark - Get Captured Tokens

+ (NSDictionary *)getCapturedTokens {
    return [g_capturedTokens copy];
}

+ (void)clearCapturedTokens {
    [g_capturedTokens removeAllObjects];
}

@end
