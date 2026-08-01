//
//  WildlifeHooks.mm
//  ZoobaProto
//
//  Hooks for Wildlife Studios classes
//  Based on real classes from Zooba IPA v6.24.2
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
    ZPLog(@"Installing Wildlife hooks...");
    ZPLog(@"===========================================");
    
    // 1. Hook PlatformAccountManager (EXISTS in IPA!)
    [self hookPlatformAccountManager];
    
    // 2. Hook NSUserDefaults
    [self hookNSUserDefaults];
    
    // 3. Hook Unity PlayerPrefs
    [self hookUnityPlayerPrefs];
    
    // 4. Hook NSURLSession
    [self hookNSURLSession];
    
    // 5. Hook Keychain (basic)
    [self hookKeychain];
    
    ZPLog(@"===========================================");
    ZPLog(@"All Wildlife hooks installed!");
    ZPLog(@"===========================================");
}

#pragma mark - 1. PlatformAccountManager Hook

+ (void)hookPlatformAccountManager {
    ZPLog(@"Hooking PlatformAccountManager...");
    
    // This class EXISTS in IPA: Wildlife.Platform.Account.PlatformAccountManager
    Class accountManagerClass = NSClassFromString(@"PlatformAccountManager");
    
    if (accountManagerClass) {
        ZPLog(@"Found PlatformAccountManager: %@", NSStringFromClass(accountManagerClass));
        [self hookAccountManagerClass:accountManagerClass];
    } else {
        ZPLog(@"PlatformAccountManager not found - trying runtime discovery");
        [self discoverAccountClasses];
    }
}

+ (void)hookAccountManagerClass:(Class)cls {
    // Hook: account property
    SEL accountSEL = NSSelectorFromString(@"account");
    if ([cls instancesRespondToSelector:accountSEL]) {
        [self hookAccountGetter:cls];
        ZPLog(@"  Hooked: account getter");
    }
    
    // Hook: CreateOrAuthenticate method
    SEL createAuthSEL = NSSelectorFromString(@"createOrAuthenticateWithCompletionHandler:");
    if ([cls instancesRespondToSelector:createAuthSEL]) {
        [self hookCreateOrAuthenticate:cls];
        ZPLog(@"  Hooked: createOrAuthenticateWithCompletionHandler:");
    }
    
    // Hook: Authenticate method
    SEL authSEL = NSSelectorFromString(@"authenticateWithCompletionHandler:");
    if ([cls instancesRespondToSelector:authSEL]) {
        [self hookAuthenticate:cls];
        ZPLog(@"  Hooked: authenticateWithCompletionHandler:");
    }
    
    // Hook: FetchAccount method
    SEL fetchSEL = NSSelectorFromString(@"fetchAccountWithCompletionHandler:");
    if ([cls instancesRespondToSelector:fetchSEL]) {
        [self hookFetchAccount:cls];
        ZPLog(@"  Hooked: fetchAccountWithCompletionHandler:");
    }
}

+ (void)hookAccountGetter:(Class)cls {
    SEL originalSEL = NSSelectorFromString(@"account");
    Method originalMethod = class_getInstanceMethod(cls, originalSEL);
    if (!originalMethod) return;
    
    IMP originalIMP = method_getImplementation(originalMethod);
    __block IMP original = originalIMP;
    
    IMP swizzledIMP = imp_implementationWithBlock(^(id self) {
        id account = ((id (*)(id, SEL))original)(self, originalSEL);
        
        if (account) {
            [self extractTokensFromAccount:account];
        }
        
        return account;
    });
    
    method_setImplementation(originalMethod, swizzledIMP);
    ZPLog(@"    Swizzled: account getter");
}

+ (void)hookCreateOrAuthenticate:(Class)cls {
    SEL originalSEL = NSSelectorFromString(@"createOrAuthenticateWithCompletionHandler:");
    if (![cls instancesRespondToSelector:originalSEL]) return;
    
    Method originalMethod = class_getInstanceMethod(cls, originalSEL);
    if (!originalMethod) return;
    
    IMP originalIMP = method_getImplementation(originalMethod);
    __block IMP original = originalIMP;
    
    IMP swizzledIMP = imp_implementationWithBlock(^(id self, id completionHandler) {
        ZPLog(@"    createOrAuthenticateWithCompletionHandler: called");
        ((void (*)(id, SEL, id))original)(self, originalSEL, completionHandler);
    });
    
    method_setImplementation(originalMethod, swizzledIMP);
    ZPLog(@"    Swizzled: createOrAuthenticateWithCompletionHandler:");
}

+ (void)hookAuthenticate:(Class)cls {
    SEL originalSEL = NSSelectorFromString(@"authenticateWithCompletionHandler:");
    if (![cls instancesRespondToSelector:originalSEL]) return;
    
    Method originalMethod = class_getInstanceMethod(cls, originalSEL);
    if (!originalMethod) return;
    
    IMP originalIMP = method_getImplementation(originalMethod);
    __block IMP original = originalIMP;
    
    IMP swizzledIMP = imp_implementationWithBlock(^(id self, id completionHandler) {
        ZPLog(@"    authenticateWithCompletionHandler: called");
        ((void (*)(id, SEL, id))original)(self, originalSEL, completionHandler);
    });
    
    method_setImplementation(originalMethod, swizzledIMP);
    ZPLog(@"    Swizzled: authenticateWithCompletionHandler:");
}

+ (void)hookFetchAccount:(Class)cls {
    SEL originalSEL = NSSelectorFromString(@"fetchAccountWithCompletionHandler:");
    if (![cls instancesRespondToSelector:originalSEL]) return;
    
    Method originalMethod = class_getInstanceMethod(cls, originalSEL);
    if (!originalMethod) return;
    
    IMP originalIMP = method_getImplementation(originalMethod);
    __block IMP original = originalIMP;
    
    IMP swizzledIMP = imp_implementationWithBlock(^(id self, id completionHandler) {
        ZPLog(@"    fetchAccountWithCompletionHandler: called");
        ((void (*)(id, SEL, id))original)(self, originalSEL, completionHandler);
    });
    
    method_setImplementation(originalMethod, swizzledIMP);
    ZPLog(@"    Swizzled: fetchAccountWithCompletionHandler:");
}

+ (void)extractTokensFromAccount:(id)account {
    if (!account) return;
    
    // Try various token properties
    NSArray *tokenProps = @[@"token", @"accessToken", @"authToken", @"bearerToken", @"idToken"];
    
    for (NSString *prop in tokenProps) {
        SEL sel = NSSelectorFromString(prop);
        if ([account respondsToSelector:sel]) {
            __weak id token = [account performSelector:sel];
            
            if (token && [token isKindOfClass:[NSString class]] && [(NSString *)token length] > 10) {
                NSString *tokenStr = (NSString *)token;
                
                // Check if it's a JWT (starts with eyJ)
                if ([tokenStr hasPrefix:@"eyJ"]) {
                    ZPTokenFound([NSString stringWithFormat:@"JWT[%@]: %@...", prop, [tokenStr substringToIndex:MIN(50, tokenStr.length)]]);
                    g_capturedTokens[[NSString stringWithFormat:@"account.%@", prop]] = tokenStr;
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"ZoobaProtoTokenFound" 
                                                                      object:nil 
                                                                    userInfo:@{@"token": tokenStr, @"source": prop}];
                }
            }
        }
    }
    
    // Try to get playerId
    SEL playerIdSEL = NSSelectorFromString(@"playerId");
    if ([account respondsToSelector:playerIdSEL]) {
        id playerId = [account performSelector:playerIdSEL];
        if (playerId && [playerId isKindOfClass:[NSString class]]) {
            ZPLog(@"    PlayerId: %@", [(NSString *)playerId substringToIndex:MIN(20, [(NSString *)playerId length])]);
            g_capturedTokens[@"account.playerId"] = playerId;
        }
    }
}

+ (void)discoverAccountClasses {
    ZPLog(@"Discovering account classes at runtime...");
    
    // Try common patterns
    NSArray *classPatterns = @[
        @"PlatformAccountManager",
        @"AccountManager",
        @"WLAuthManager",
        @"WildlifeAccount",
        @"PlayerAccount"
    ];
    
    for (NSString *pattern in classPatterns) {
        Class cls = NSClassFromString(pattern);
        if (cls) {
            ZPLog(@"  Found: %@", pattern);
            [self hookAccountManagerClass:cls];
        }
    }
}

#pragma mark - 2. NSUserDefaults Hook

+ (void)hookNSUserDefaults {
    ZPLog(@"Hooking NSUserDefaults...");
    
    Class defaultsClass = [NSUserDefaults class];
    
    // Hook: dictionaryForKey:
    SEL dictSEL = NSSelectorFromString(@"dictionaryForKey:");
    if ([defaultsClass instancesRespondToSelector:dictSEL]) {
        [self hookNSUserDefaultsDictionary:defaultsClass];
    }
    
    // Hook: stringForKey:
    SEL stringSEL = NSSelectorFromString(@"stringForKey:");
    if ([defaultsClass instancesRespondToSelector:stringSEL]) {
        [self hookNSUserDefaultsString:defaultsClass];
    }
    
    // Hook: dataForKey:
    SEL dataSEL = NSSelectorFromString(@"dataForKey:");
    if ([defaultsClass instancesRespondToSelector:dataSEL]) {
        [self hookNSUserDefaultsData:defaultsClass];
    }
}

+ (void)hookNSUserDefaultsDictionary:(Class)cls {
    SEL originalSEL = NSSelectorFromString(@"dictionaryForKey:");
    Method originalMethod = class_getInstanceMethod(cls, originalSEL);
    if (!originalMethod) return;
    
    IMP originalIMP = method_getImplementation(originalMethod);
    __block IMP original = originalIMP;
    
    IMP swizzledIMP = imp_implementationWithBlock(^(id self, NSString *key) {
        id result = ((id (*)(id, SEL, NSString *))original)(self, originalSEL, key);
        
        if (result && [result isKindOfClass:[NSDictionary class]] && key) {
            [self checkDefaultsValue:result forKey:key];
        }
        
        return result;
    });
    
    method_setImplementation(originalMethod, swizzledIMP);
    ZPLog(@"  Swizzled: dictionaryForKey:");
}

+ (void)hookNSUserDefaultsString:(Class)cls {
    SEL originalSEL = NSSelectorFromString(@"stringForKey:");
    Method originalMethod = class_getInstanceMethod(cls, originalSEL);
    if (!originalMethod) return;
    
    IMP originalIMP = method_getImplementation(originalMethod);
    __block IMP original = originalIMP;
    
    IMP swizzledIMP = imp_implementationWithBlock(^(id self, NSString *key) {
        id result = ((id (*)(id, SEL, NSString *))original)(self, originalSEL, key);
        
        if (result && [result isKindOfClass:[NSString class]] && [(NSString *)result length] > 10 && key) {
            [self checkDefaultsValue:result forKey:key];
        }
        
        return result;
    });
    
    method_setImplementation(originalMethod, swizzledIMP);
    ZPLog(@"  Swizzled: stringForKey:");
}

+ (void)hookNSUserDefaultsData:(Class)cls {
    SEL originalSEL = NSSelectorFromString(@"dataForKey:");
    Method originalMethod = class_getInstanceMethod(cls, originalSEL);
    if (!originalMethod) return;
    
    IMP originalIMP = method_getImplementation(originalMethod);
    __block IMP original = originalIMP;
    
    IMP swizzledIMP = imp_implementationWithBlock(^(id self, NSString *key) {
        id result = ((id (*)(id, SEL, NSString *))original)(self, originalSEL, key);
        
        if (result && [result isKindOfClass:[NSData class]] && key) {
            [self checkDefaultsValue:result forKey:key];
        }
        
        return result;
    });
    
    method_setImplementation(originalMethod, swizzledIMP);
    ZPLog(@"  Swizzled: dataForKey:");
}

+ (void)checkDefaultsValue:(id)value forKey:(NSString *)key {
    if (!value || !key) return;
    
    NSString *keyLower = [key lowercaseString];
    
    // Check for token patterns
    NSArray *tokenPatterns = @[@"token", @"auth", @"session", @"account", @"player"];
    BOOL isToken = NO;
    
    for (NSString *pattern in tokenPatterns) {
        if ([keyLower containsString:pattern]) {
            isToken = YES;
            break;
        }
    }
    
    if (isToken) {
        NSString *valueStr = nil;
        
        if ([value isKindOfClass:[NSString class]]) {
            valueStr = (NSString *)value;
        } else if ([value isKindOfClass:[NSData class]]) {
            valueStr = [[NSString alloc] initWithData:(NSData *)value encoding:NSUTF8StringEncoding];
        }
        
        if (valueStr && valueStr.length > 10) {
            ZPLog(@"🎯 NSUserDefaults[%@] = %@...", key, [valueStr substringToIndex:MIN(50, valueStr.length)]);
            g_capturedTokens[[NSString stringWithFormat:@"defaults.%@", key]] = valueStr;
            
            // Check for JWT
            if ([valueStr hasPrefix:@"eyJ"]) {
                ZPTokenFound([NSString stringWithFormat:@"NSUserDefaults JWT[%@]: %@...", key, [valueStr substringToIndex:MIN(50, valueStr.length)]]);
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ZoobaProtoTokenFound" 
                                                                  object:nil 
                                                                userInfo:@{@"token": valueStr, @"source": [NSString stringWithFormat:@"NSUserDefaults.%@", key]}];
            }
        }
    }
}

#pragma mark - 3. Unity PlayerPrefs Hook

+ (void)hookUnityPlayerPrefs {
    ZPLog(@"Hooking Unity PlayerPrefs...");
    
    Class playerPrefsClass = NSClassFromString(@"PlayerPrefs");
    if (playerPrefsClass) {
        ZPLog(@"Found PlayerPrefs class!");
        
        // Hook GetString
        [self hookPlayerPrefsGetString:playerPrefsClass];
        
        // Hook SetString
        [self hookPlayerPrefsSetString:playerPrefsClass];
    } else {
        ZPLog(@"PlayerPrefs class not found");
    }
}

+ (void)hookPlayerPrefsGetString:(Class)cls {
    SEL originalSEL = NSSelectorFromString(@"GetString:");
    Method originalMethod = class_getInstanceMethod(cls, originalSEL);
    if (!originalMethod) return;
    
    IMP originalIMP = method_getImplementation(originalMethod);
    __block IMP original = originalIMP;
    
    IMP swizzledIMP = imp_implementationWithBlock(^(NSString *key) {
        id value = ((id (*)(Class, SEL, NSString *))original)(cls, originalSEL, key);
        
        if (value && [value isKindOfClass:[NSString class]] && [(NSString *)value length] > 10) {
            [self checkPlayerPrefsValue:value forKey:key];
        }
        
        return value;
    });
    
    method_setImplementation(originalMethod, swizzledIMP);
    ZPLog(@"  Swizzled: GetString:");
}

+ (void)hookPlayerPrefsSetString:(Class)cls {
    SEL originalSEL = NSSelectorFromString(@"SetString:forKey:");
    Method originalMethod = class_getInstanceMethod(cls, originalSEL);
    if (!originalMethod) return;
    
    IMP originalIMP = method_getImplementation(originalMethod);
    __block IMP original = originalIMP;
    
    IMP swizzledIMP = imp_implementationWithBlock(^(NSString *value, NSString *key) {
        ZPLog(@"📝 PlayerPrefs SET: %@ = %@...", key, [value substringToIndex:MIN(30, value.length)]);
        ((void (*)(Class, SEL, NSString *, NSString *))original)(cls, originalSEL, value, key);
    });
    
    method_setImplementation(originalMethod, swizzledIMP);
    ZPLog(@"  Swizzled: SetString:forKey:");
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

#pragma mark - 4. NSURLSession Hook

+ (void)hookNSURLSession {
    ZPLog(@"Hooking NSURLSession...");
    
    Class sessionClass = [NSURLSession class];
    
    // Hook dataTaskWithRequest:completionHandler:
    [self hookNSURLSessionDataTask];
    
    // Hook sendRequest:completionHandler:
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
        
        NSDictionary *headers = request.allHTTPHeaderFields;
        if (headers) {
            [self checkHeadersForTokens:headers];
        }
        
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

+ (void)checkHeadersForTokens:(NSDictionary *)headers {
    if (!headers) return;
    
    for (NSString *key in headers) {
        NSString *value = headers[key];
        
        if (![value isKindOfClass:[NSString class]]) continue;
        
        // Check Authorization header
        if ([key.lowercaseString isEqualToString:@"authorization"]) {
            ZPLog(@"🎯 Auth Header: %@", [value substringToIndex:MIN(60, value.length)]);
            g_capturedTokens[@"http.Authorization"] = value;
            
            if ([value hasPrefix:@"Bearer "]) {
                NSString *token = [value substringFromIndex:7];
                ZPTokenFound([NSString stringWithFormat:@"Bearer Token: %@...", [token substringToIndex:MIN(50, token.length)]]);
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ZoobaProtoTokenFound" 
                                                                  object:nil 
                                                                userInfo:@{@"token": token, @"source": @"Authorization Bearer"}];
            }
        }
        
        // Check Wildlife headers
        if ([key.lowercaseString containsString:@"wildlife"] || 
            [key.lowercaseString containsString:@"x-"]) {
            ZPLog(@"    %@: %@", key, [value substringToIndex:MIN(50, value.length)]);
            
            if ([value hasPrefix:@"eyJ"]) {
                g_capturedTokens[[NSString stringWithFormat:@"http.%@", key]] = value;
            }
        }
    }
}

#pragma mark - 5. Keychain Hook (Basic)

+ (void)hookKeychain {
    ZPLog(@"Hooking Keychain...");
    ZPLog(@"  Note: Full Keychain hooking requires fishhook for SecItem functions");
}

#pragma mark - Get Captured Tokens

+ (NSDictionary *)getCapturedTokens {
    return [g_capturedTokens copy];
}

+ (void)clearCapturedTokens {
    [g_capturedTokens removeAllObjects];
}

@end
