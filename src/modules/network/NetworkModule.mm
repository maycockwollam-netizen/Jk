//
//  NetworkModule.mm
//  ZoobaProto
//
//  Network traffic monitoring
//

#import "NetworkModule.h"
#import "Config.h"
#import "StorageModule.h"
#import "UtilsModule.h"

#define ZPLog(fmt, args...) NSLog(@"[ZoobaProto/Network] " fmt, ##args)

@implementation NetworkModule

- (void)setup {
    ZPLog(@"Setting up Network module...");
    [self installHooks];
    ZPLog(@"Network module ready");
}

- (void)teardown {
    ZPLog(@"Tearing down Network module...");
}

#pragma mark - Hook Installation

- (void)installHooks {
    ZPLog(@"Installing network hooks...");
    
    // Hook NSURLSession
    [self hookNSURLSession];
    
    // Hook NSURLConnection (legacy)
    [self hookNSURLConnection];
    
    // Hook custom HTTP clients
    [self hookCustomClients];
    
    ZPLog(@"Network hooks installed");
}

- (void)hookNSURLSession {
    // Hook NSURLSession dataTask methods
    // This would use Method Swizzling or fishhook
    
    Class nsUrlSessionClass = NSClassFromString(@"NSURLSession");
    if (nsUrlSessionClass) {
        ZPLog(@"Found NSURLSession class");
        
        // In real implementation, would swizzle:
        // - dataTaskWithRequest:
        // - sendRequest:
        // - delegate methods
    }
}

- (void)hookNSURLConnection {
    Class nsUrlConnectionClass = NSClassFromString(@"NSURLConnection");
    if (nsUrlConnectionClass) {
        ZPLog(@"Found NSURLConnection class (legacy)");
    }
}

- (void)hookCustomClients {
    // Hook custom networking libraries
    NSArray *clientClasses = @[
        @"AFNetworking",
        @"Alamofire",
        @"WLNetworkClient",
        @"PitayaClient"
    ];
    
    for (NSString *className in clientClasses) {
        Class cls = NSClassFromString(className);
        if (cls) {
            ZPLog(@"Found client class: %@", className);
        }
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
    NSArray *authHeaderNames = @[
        @"Authorization",
        @"authorization",
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
            if ([headerName.lowercaseString isEqualToString:@"authorization"]) {
                if ([value.lowercaseString hasPrefix:@"bearer "]) {
                    NSString *token = [value substringFromIndex:7];
                    ZPLog(@"🎉 BEARER TOKEN FOUND: Bearer %@", token);
                    
                    // Notify
                    if ([Config shared].notifyOnToken) {
                        [[UtilsModule shared] notifyTokenFound:[NSString stringWithFormat:@"Bearer %@", token]];
                    }
                }
            }
        }
    }
}

- (void)checkForTokenInBody:(NSData *)body {
    if (!body) return;
    
    // Look for patterns
    NSArray *patterns = @[
        @"\"accessToken\"\\s*:\\s*\"([^\"]+)\"",
        @"\"token\"\\s*:\\s*\"([^\"]+)\"",
        @"\"authToken\"\\s*:\\s*\"([^\"]+)\"",
        @"Bearer\\s+([A-Za-z0-9-_]+\\.[A-Za-z0-9-_]+\\.[A-Za-z0-9-_]+)",
        @"eyJ[A-Za-z0-9-_]+"
    ];
    
    NSString *bodyString = [[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding];
    if (!bodyString) return;
    
    for (NSString *pattern in patterns) {
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
                ZPLog(@"🔑 TOKEN PATTERN: %@", found);
            }
        }
    }
}

@end
