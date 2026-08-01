//
//  StorageModule.mm
//  ZoobaProto
//
//  Token storage and retrieval
//

#import "StorageModule.h"
#import "Config.h"
#import <Security/Security.h>

#define ZPLog(fmt, args...) NSLog(@"[ZoobaProto/Storage] " fmt, ##args)

#pragma mark - ZPToken

@implementation ZPToken

- (instancetype)initWithKey:(NSString *)key value:(NSString *)value {
    return [self initWithKey:key value:value type:ZPStorageTypeUserDefaults];
}

- (instancetype)initWithKey:(NSString *)key value:(NSString *)value type:(ZPStorageType)type {
    self = [super init];
    if (self) {
        _key = key;
        _value = value;
        _storageType = type;
        _foundAt = [NSDate date];
        
        if ([value hasPrefix:@"eyJ"]) {
            _bearerFormat = [self bearerString];
        }
    }
    return self;
}

- (NSString *)bearerString {
    return [NSString stringWithFormat:@"Bearer %@", self.value];
}

@end

#pragma mark - StorageModule

@interface StorageModule ()
@property (nonatomic, strong) NSMutableDictionary<NSString *, ZPToken *> *foundTokens;
@property (nonatomic, strong) NSMutableArray<NSString *> *tokenKeys;
@end

@implementation StorageModule

- (instancetype)init {
    self = [super init];
    if (self) {
        _foundTokens = [NSMutableDictionary dictionary];
        _tokenKeys = [NSMutableArray array];
        
        // Wildlife Platform storage keys (VERIFIED from reverse engineering)
        // Source: Wildlife.Platform.Core.dll.cs
        
        // === PlatformAccountManager ===
        // PlayerPrefsLastAccountKey - stores last logged in account ID
        [_tokenKeys addObjectsFromArray:@[
            @"wildlife_last_account",
            @"wl_last_account",
            @"last_account_id",
            
            // === PlayerAccount SecurityToken ===
            // PlayerAccount.SecurityToken - JWT token
            @"securityToken",
            @"security_token",
            @"platform_security_token",
            
            // === AccessToken from AuthenticatePlayerArgs ===
            @"accessToken",
            @"access_token",
            @"auth_access_token",
            
            // === PlayerAccount.Id ===
            @"accountId",
            @"account_id",
            @"player_account_id",
            
            // === PlayerAccount.TenantId ===
            @"tenantId",
            @"tenant_id",
            
            // === File Storage ===
            // player_data.json - Unity player data
            @"player_data_json",
            
            // === Generic ===
            @"bearer_token",
            @"bearerToken",
            @"auth_token",
            @"session_token",
            @"jwt_token"
        ]];
    }
    return self;
}

#pragma mark - Setup

- (void)setup {
    ZPLog(@"Setting up Storage module...");
    
    // Try to dump initial tokens
    [self dumpAllTokens];
    
    ZPLog(@"Storage module ready");
}

- (void)teardown {
    ZPLog(@"Tearing down Storage module...");
    [self.foundTokens removeAllObjects];
}

#pragma mark - Token Operations

- (NSString *)findBearerToken {
    NSString *accessToken = [self findAccessToken];
    if (accessToken) {
        return [NSString stringWithFormat:@"Bearer %@", accessToken];
    }
    return nil;
}

- (NSString *)findAccessToken {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *allDefaults = [defaults dictionaryRepresentation];
    
    for (NSString *key in allDefaults.allKeys) {
        NSString *lowercaseKey = [key lowercaseString];
        for (NSString *pattern in @[@"token", @"auth", @"access"]) {
            if ([lowercaseKey containsString:pattern]) {
                NSString *value = allDefaults[key];
                if (value && [value isKindOfClass:[NSString class]] && value.length > 10) {
                    ZPLog(@"Found access token: %@", key);
                    return value;
                }
            }
        }
    }
    
    return nil;
}

- (NSString *)findPlayerId {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSArray *keys = @[@"player_id", @"playerId", @"uid", @"user_id", @"wildlife_player_id"];
    
    for (NSString *key in keys) {
        NSString *playerId = [defaults stringForKey:key];
        if (playerId && playerId.length > 0) {
            return playerId;
        }
    }
    
    return nil;
}

- (NSString *)findSessionToken {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    for (NSString *key in defaults.allKeys) {
        NSString *lowercaseKey = [key lowercaseString];
        if ([lowercaseKey containsString:@"session"]) {
            NSString *value = [defaults stringForKey:key];
            if (value && value.length > 10) {
                return value;
            }
        }
    }
    
    return nil;
}

#pragma mark - Dump

- (void)dumpAllTokens {
    ZPLog(@"========== TOKEN DUMP ==========");
    
    // Dump UserDefaults
    NSArray *udTokens = [self dumpFromUserDefaults];
    for (ZPToken *token in udTokens) {
        ZPLog(@"📦 UserDefaults: %@ = %@", token.key, token.value);
        self.foundTokens[token.key] = token;
    }
    
    // Dump Keychain
    if ([Config shared].enableKeychainDump) {
        NSArray *kcTokens = [self dumpFromKeychain];
        for (ZPToken *token in kcTokens) {
            ZPLog(@"🔐 Keychain: %@ = %@", token.key, token.value);
            self.foundTokens[token.key] = token;
        }
    }
    
    // Check for Bearer
    NSString *bearer = [self findBearerToken];
    if (bearer) {
        ZPLog(@"🎉 BEARER TOKEN: %@", bearer);
    } else {
        ZPLog(@"No Bearer token found");
    }
    
    ZPLog(@"================================");
}

- (NSArray<ZPToken *> *)dumpFromUserDefaults {
    NSMutableArray<ZPToken *> *tokens = [NSMutableArray array];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *allDefaults = [defaults dictionaryRepresentation];
    
    for (NSString *key in allDefaults.allKeys) {
        if ([self isTokenKey:key]) {
            id value = allDefaults[key];
            if ([value isKindOfClass:[NSString class]]) {
                ZPToken *token = [[ZPToken alloc] initWithKey:key value:value type:ZPStorageTypeUserDefaults];
                [tokens addObject:token];
            }
        }
    }
    
    return tokens;
}

- (NSArray<ZPToken *> *)dumpFromKeychain {
    NSMutableArray<ZPToken *> *tokens = [NSMutableArray array];
    
    // Keychain query
    NSDictionary *query = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecReturnAttributes: @YES,
        (__bridge id)kSecReturnData: @YES,
        (__bridge id)kSecMatchLimit: @100
    };
    
    CFTypeRef result = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
    
    if (status == errSecSuccess && result) {
        NSArray *items = (__bridge_transfer NSArray *)result;
        
        for (NSDictionary *item in items) {
            NSString *account = item[(__bridge id)kSecAttrAccount];
            NSData *data = item[(__bridge id)kSecValueData];
            
            if (account && data) {
                NSString *value = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                if (value && [self isTokenKey:account]) {
                    ZPToken *token = [[ZPToken alloc] initWithKey:account value:value type:ZPStorageTypeKeychain];
                    [tokens addObject:token];
                }
            }
        }
    }
    
    return tokens;
}

- (BOOL)isTokenKey:(NSString *)key {
    NSString *lowercaseKey = [key lowercaseString];
    for (NSString *pattern in [Config shared].tokenKeyPatterns) {
        if ([lowercaseKey containsString:[pattern lowercaseString]]) {
            return YES;
        }
    }
    return NO;
}

#pragma mark - Save

- (void)saveToken:(NSString *)token {
    [self saveToken:token withKey:@"zooba_bearer_token"];
}

- (void)saveToken:(NSString *)token withKey:(NSString *)key {
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"tokens.json"];
    
    NSMutableDictionary *tokens = [NSMutableDictionary dictionary];
    
    // Load existing
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSData *data = [NSData dataWithContentsOfFile:path];
        if (data) {
            tokens = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            if (![tokens isKindOfClass:[NSMutableDictionary class]]) {
                tokens = [NSMutableDictionary dictionary];
            }
        }
    }
    
    // Add new token
    tokens[key] = @{
        @"token": token,
        @"timestamp": @([[NSDate date] timeIntervalSince1970])
    };
    
    // Save
    NSData *data = [NSJSONSerialization dataWithJSONObject:tokens options:NSJSONWritingPrettyPrinted error:nil];
    [data writeToFile:path atomically:YES];
    
    ZPLog(@"Saved token to: %@", path);
}

#pragma mark - Proto Definitions

static NSMutableArray *g_savedProtoDefinitions = nil;

- (void)saveProtoDefinitions:(NSDictionary *)protoData {
    if (!protoData) return;
    
    @synchronized (self) {
        if (!g_savedProtoDefinitions) {
            g_savedProtoDefinitions = [NSMutableArray array];
        }
        
        [g_savedProtoDefinitions addObject:protoData];
        
        // Save to file
        [self saveProtoDefinitionsToFile];
        
        ZPLog(@"Saved proto definitions: %@", protoData[@"filename"]);
    }
}

- (NSArray *)getAllProtoDefinitions {
    @synchronized (self) {
        if (!g_savedProtoDefinitions || g_savedProtoDefinitions.count == 0) {
            [self loadProtoDefinitionsFromFile];
        }
        return [g_savedProtoDefinitions copy];
    }
}

- (void)clearProtoDefinitions {
    @synchronized (self) {
        [g_savedProtoDefinitions removeAllObjects];
        [self deleteProtoDefinitionsFile];
        ZPLog(@"Cleared all proto definitions");
    }
}

- (NSString *)protoDefinitionsFilePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = paths.firstObject;
    return [documentsPath stringByAppendingPathComponent:@"zooba_proto_definitions.json"];
}

- (void)saveProtoDefinitionsToFile {
    if (!g_savedProtoDefinitions || g_savedProtoDefinitions.count == 0) return;
    
    NSError *error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:g_savedProtoDefinitions 
                                                  options:NSJSONWritingPrettyPrinted 
                                                    error:&error];
    
    if (error) {
        ZPLog(@"Error serializing proto definitions: %@", error.localizedDescription);
        return;
    }
    
    NSString *path = [self protoDefinitionsFilePath];
    BOOL success = [data writeToFile:path atomically:YES];
    
    if (success) {
        ZPLog(@"Proto definitions saved to: %@", path);
    }
}

- (void)loadProtoDefinitionsFromFile {
    NSString *path = [self protoDefinitionsFilePath];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        ZPLog(@"No saved proto definitions found");
        return;
    }
    
    NSData *data = [NSData dataWithContentsOfFile:path];
    if (!data) return;
    
    NSError *error;
    NSArray *definitions = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    
    if (error || ![definitions isKindOfClass:[NSArray class]]) {
        ZPLog(@"Error loading proto definitions: %@", error.localizedDescription);
        return;
    }
    
    if (!g_savedProtoDefinitions) {
        g_savedProtoDefinitions = [NSMutableArray array];
    }
    
    [g_savedProtoDefinitions removeAllObjects];
    [g_savedProtoDefinitions addObjectsFromArray:definitions];
    
    ZPLog(@"Loaded %lu proto definitions", (unsigned long)g_savedProtoDefinitions.count);
}

- (void)deleteProtoDefinitionsFile {
    NSString *path = [self protoDefinitionsFilePath];
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
}

#pragma mark - Clear

- (void)clearAllTokens {
    [self.foundTokens removeAllObjects];
    ZPLog(@"Cleared all stored tokens");
}

@end
