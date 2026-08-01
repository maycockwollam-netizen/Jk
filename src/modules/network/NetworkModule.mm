//
//  NetworkModule.mm
//  ZoobaProto
//
//  Network traffic monitoring
//  Based on reverse-engineered Zooba code analysis
//

#import <objc/runtime.h>
#import "NetworkModule.h"
#import "config/Config.h"
#import "StorageModule.h"
#import "UtilsModule.h"

#define ZPLog(fmt, args...) NSLog(@"[ZoobaProto/Network] " fmt, ##args)

@implementation NetworkModule

- (void)setup {
    ZPLog(@"Setting up Network module...");
    ZPLog(@"Targeting Wildlife Platform networking classes...");
    
    // Hook Wildlife Platform networking
    [self hookWildlifeNetworking];
    
    // Hook Unity WWW/UnityWebRequest
    [self hookUnityNetworking];
    
    // Hook NSURLSession
    [self hookNSURLSession];
    
    ZPLog(@"Network module ready");
}

- (void)teardown {
    ZPLog(@"Tearing down Network module...");
}

#pragma mark - Wildlife Platform Hooks

- (void)hookWildlifeNetworking {
    ZPLog(@"Hooking Wildlife Platform networking...");
    
    // Wildlife Platform uses:
    // - PlatformNetworking (C#) -> PlatformNetworkingIOSBinding (ObjC)
    // - UnityWebRequestBridge (ObjC to Unity)
    
    Class platformNetworkingIOSClass = NSClassFromString(@"PlatformNetworkingIOSBinding");
    if (platformNetworkingIOSClass) {
        ZPLog(@"Found PlatformNetworkingIOSBinding!");
        [self hookPlatformNetworkingIOSBinding:platformNetworkingIOSClass];
    }
    
    // Try alternative names
    NSArray *wildlifeNetworkClasses = @[
        @"WLNetworkClient",
        @"WLNetworking",
        @"WildlifeNetworking",
        @"PlatformNetworking",
        @"UnityWebRequestBridge"
    ];
    
    for (NSString *className in wildlifeNetworkClasses) {
        Class cls = NSClassFromString(className);
        if (cls) {
            ZPLog(@"Found Wildlife network class: %@", className);
            [self hookWildlifeNetworkClass:cls];
        }
    }
}

- (void)hookPlatformNetworkingIOSBinding:(Class)cls {
    // PlatformNetworkingIOSBinding methods to hook:
    // - SendRequest:WithOptions:Body:Headers:Callback:
    // - SetPlatformHeader:Value:
    // - GetPlatformHeaders
    
    unsigned int methodCount = 0;
    Method *methods = class_copyMethodList(cls, &methodCount);
    
    for (unsigned int i = 0; i < methodCount; i++) {
        Method method = methods[i];
        SEL selector = method_getName(method);
        NSString *methodName = NSStringFromSelector(selector);
        
        // Look for interesting methods
        if ([self isInterestingNetworkMethod:methodName]) {
            ZPLog(@"  Hooking: %@", methodName);
            // Would swizzle here
        }
    }
    
    free(methods);
}

- (void)hookWildlifeNetworkClass:(Class)cls {
    unsigned int methodCount = 0;
    Method *methods = class_copyMethodList(cls, &methodCount);
    
    for (unsigned int i = 0; i < methodCount; i++) {
        Method method = methods[i];
        SEL selector = method_getName(method);
        NSString *methodName = NSStringFromSelector(selector);
        
        // Log all methods for analysis
        ZPLog(@"  [%@] %@", NSStringFromClass(cls), methodName);
        
        // Hook specific methods
        if ([methodName containsString:@"SendRequest"] ||
            [methodName containsString:@"SetHeader"] ||
            [methodName containsString:@"AddHeader"] ||
            [methodName containsString:@"Authorization"]) {
            ZPLog(@"    -> Will hook this method!");
            // Swizzle here
        }
    }
    
    free(methods);
}

- (BOOL)isInterestingNetworkMethod:(NSString *)methodName {
    NSArray *interestingPatterns = @[
        @"SendRequest",
        @"SetHeader",
        @"AddHeader", 
        @"SetAuth",
        @"SetToken",
        @"AddAuthorization",
        @"SetPlatformHeader",
        @"GetHeaders",
        @"GetPlatformHeaders",
        @"Request",
        @"Response"
    ];
    
    for (NSString *pattern in interestingPatterns) {
        if ([methodName containsString:pattern]) {
            return YES;
        }
    }
    return NO;
}

#pragma mark - Unity Networking Hooks

- (void)hookUnityNetworking {
    ZPLog(@"Hooking Unity networking...");
    
    // Unity uses:
    // - UnityEngine.WWW
    // - UnityEngine.Networking.UnityWebRequest
    
    Class unityWwwClass = NSClassFromString(@"UnityEngine.WWW");
    if (unityWwwClass) {
        ZPLog(@"Found Unity WWW class!");
        [self hookUnityWWW:unityWwwClass];
    }
    
    Class unityWebRequestClass = NSClassFromString(@"UnityEngine.Networking.UnityWebRequest");
    if (unityWebRequestClass) {
        ZPLog(@"Found UnityWebRequest class!");
        [self hookUnityWebRequest:unityWebRequestClass];
    }
}

- (void)hookUnityWWW:(Class)cls {
    // Unity WWW methods to hook:
    // - set_requestHeaders:
    // - responseHeaders
    // - text
    
    ZPLog(@"Hooking Unity WWW methods...");
}

- (void)hookUnityWebRequest:(Class)cls {
    // UnityWebRequest methods:
    // - SetRequestHeader:
    // - get_requestHeaders
    // - SendWebRequest
    
    ZPLog(@"Hooking UnityWebRequest methods...");
}

#pragma mark - NSURLSession Hooks

- (void)hookNSURLSession {
    ZPLog(@"Hooking NSURLSession...");
    
    Class nsUrlSessionClass = NSClassFromString(@"NSURLSession");
    if (nsUrlSessionClass) {
        ZPLog(@"Found NSURLSession class");
        
        // Hook dataTaskWithRequest:completionHandler:
        // Hook sendRequest:completionHandler:
    }
}

#pragma mark - Monitoring

- (void)onRequest:(NSURLRequest *)request {
    if (![Config shared].enableNetworkHook) return;
    
    ZPLog(@"========== HTTP REQUEST ==========");
    ZPLog(@"URL: %@", request.URL.absoluteString);
    ZPLog(@"Method: %@", request.HTTPMethod);
    
    // Log headers
    NSDictionary *headers = request.allHTTPHeaderFields;
    if (headers.count > 0) {
        ZPLog(@"Headers:");
        for (NSString *key in headers.allKeys) {
            ZPLog(@"  %@: %@", key, headers[key]);
        }
        [self checkForTokenInHeaders:headers];
    }
    
    // Log body
    NSData *body = request.HTTPBody;
    if (body) {
        ZPLog(@"Body size: %lu bytes", (unsigned long)body.length);
        [self checkForTokenInBody:body];
    }
    
    ZPLog(@"===================================");
}

- (void)onResponse:(NSHTTPURLResponse *)response data:(NSData *)data {
    if (![Config shared].enableNetworkHook) return;
    
    ZPLog(@"========== HTTP RESPONSE ==========");
    ZPLog(@"Status: %ld", (long)response.statusCode);
    ZPLog(@"URL: %@", response.URL.absoluteString);
    
    // Check headers
    [self checkForTokenInHeaders:response.allHeaderFields];
    
    // Check body
    if (data) {
        ZPLog(@"Body size: %lu bytes", (unsigned long)data.length);
        [self checkForTokenInBody:data];
    }
    
    ZPLog(@"====================================");
}

#pragma mark - Token Detection

- (void)checkForTokenInHeaders:(NSDictionary *)headers {
    // Wildlife Platform uses these auth header names:
    NSArray *authHeaderNames = @[
        @"Authorization",
        @"authorization",
        @"X-Security-Token",
        @"X-Player-Id",
        @"X-Platform-Token",
        @"Auth-Token",
        @"X-Auth-Token",
        @"X-Access-Token",
        @"Bearer",
        @"Token"
    ];
    
    for (NSString *headerName in authHeaderNames) {
        NSString *value = headers[headerName];
        if (value && value.length > 0) {
            ZPLog(@"🔑 AUTH HEADER: %@ = %@", headerName, value);
            
            // Extract Bearer token
            NSString *lowercaseName = [headerName lowercaseString];
            if ([lowercaseName isEqualToString:@"authorization"]) {
                if ([value.lowercaseString hasPrefix:@"bearer "]) {
                    NSString *token = [value substringFromIndex:7];
                    ZPLog(@"🎉 BEARER TOKEN (Authorization): Bearer %@", [self truncateToken:token]);
                    [self onTokenFound:[NSString stringWithFormat:@"Bearer %@", token]];
                } else if ([value hasPrefix:@"eyJ"]) {
                    // Raw JWT
                    ZPLog(@"🎉 JWT TOKEN: %@", [self truncateToken:value]);
                    [self onTokenFound:[NSString stringWithFormat:@"Bearer %@", value]];
                }
            } else if ([lowercaseName containsString:@"token"] || 
                       [lowercaseName containsString:@"security"]) {
                ZPLog(@"🎉 SECURITY TOKEN: %@", [self truncateToken:value]);
                [self onTokenFound:value];
            }
        }
    }
}

- (void)checkForTokenInBody:(NSData *)body {
    if (!body) return;
    
    // Look for Wildlife Platform patterns
    // Based on ProtoBuf messages like AuthenticateArgs:
    // - id (player ID)
    // - securityToken (JWT token)
    // - additionalArgs
    
    NSString *bodyString = [[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding];
    if (!bodyString) {
        // Try to find patterns in binary
        [self checkBinaryForTokens:body];
        return;
    }
    
    // JSON patterns
    NSArray *jsonPatterns = @[
        @"\"securityToken\"\\s*:\\s*\"([^\"]+)\"",
        @"\"accessToken\"\\s*:\\s*\"([^\"]+)\"",
        @"\"token\"\\s*:\\s*\"([^\"]+)\"",
        @"\"authToken\"\\s*:\\s*\"([^\"]+)\"",
        @"\"bearer\"\\s*:\\s*\"([^\"]+)\"",
        @"\"id\"\\s*:\\s*\"([^\"]+)\".*?\"securityToken\"",
        @"eyJ[A-Za-z0-9-_]+"  // JWT pattern
    ];
    
    for (NSString *pattern in jsonPatterns) {
        NSError *error;
        NSRegularExpression *regex = [NSRegularExpression 
            regularExpressionWithPattern:pattern 
                                   options:0 
                                     error:&error];
        
        if (!error) {
            NSArray *matches = [regex matchesInString:bodyString 
                                              options:0 
                                                range:NSMakeRange(0, bodyString.length)];
            
            for (NSTextCheckingResult *match in matches) {
                NSString *found = [bodyString substringWithRange:match.range];
                if ([found hasPrefix:@"eyJ"]) {
                    ZPLog(@"🎉 JWT IN BODY: %@", [self truncateToken:found]);
                    [self onTokenFound:[NSString stringWithFormat:@"Bearer %@", found]];
                } else {
                    ZPLog(@"🔑 TOKEN PATTERN IN BODY: %@", found);
                }
            }
        }
    }
}

- (void)checkBinaryForTokens:(NSData *)data {
    // Look for JWT patterns in binary data
    // JWT starts with "eyJ" (base64url of '{"')
    
    const unsigned char *bytes = (const unsigned char *)data.bytes;
    NSUInteger length = data.length;
    
    // Search for "eyJ" pattern
    for (NSUInteger i = 0; i < length - 3; i++) {
        if (bytes[i] == 'e' && bytes[i+1] == 'y' && 
            (bytes[i+2] == 'J' || bytes[i+2] == 'I')) {
            // Found potential JWT start
            NSUInteger start = i;
            NSUInteger end = MIN(start + 300, length);
            
            // Extract potential JWT
            NSData *jwtData = [data subdataWithRange:NSMakeRange(start, end - start)];
            NSString *jwt = [[NSString alloc] initWithData:jwtData encoding:NSUTF8StringEncoding];
            
            if (jwt && [jwt length] > 50) {
                // Verify it's a valid JWT format (xxx.yyy.zzz)
                NSArray *parts = [jwt componentsSeparatedByString:@"."];
                if (parts.count == 3) {
                    ZPLog(@"🎉 JWT FOUND IN BINARY at offset %lu!", (unsigned long)start);
                    ZPLog(@"    Token: %@", [self truncateToken:jwt]);
                    [self onTokenFound:[NSString stringWithFormat:@"Bearer %@", jwt]];
                    return;
                }
            }
        }
    }
}

- (void)onTokenFound:(NSString *)token {
    // Notify
    if ([Config shared].notifyOnToken) {
        [[UtilsModule shared] notifyTokenFound:token];
    }
    
    // Save
    if ([Config shared].autoSaveToken) {
        [[StorageModule shared] saveToken:token];
    }
}

- (NSString *)truncateToken:(NSString *)token {
    if (token.length > 50) {
        return [[token substringToIndex:50] stringByAppendingString:@"..."];
    }
    return token;
}

@end
