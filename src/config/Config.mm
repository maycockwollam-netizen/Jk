//
//  Config.mm
//  ZoobaProto
//
//  Configuration management
//

#import "Config.h"

static NSString * const kConfigFileName = @"ZoobaProto.config";
static NSString * const kConfigVersion = @"2.0.0";

@implementation Config

+ (instancetype)shared {
    static Config *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[Config alloc] init];
        [instance loadDefaults];
        [instance loadFromFile];
        
        // Validate on first load
        if (![instance validateConfig]) {
            NSLog(@"[ZoobaProto/Config] Config validation failed: %@", [instance configValidationErrors]);
        }
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // Will be set by loadDefaults
    }
    return self;
}

#pragma mark - Defaults

- (void)loadDefaults {
    // ========== FEATURES ==========
    _enableTokenDump = YES;
    _enableNetworkHook = YES;
    _enablePitayaHook = YES;
    _enableKeychainDump = YES;
    _enableFileLogging = NO;
    _notifyOnToken = YES;
    _autoSaveToken = YES;
    _enableUIPanel = YES;
    _enablePeriodicDump = YES;
    
    // ========== LOGGING ==========
    _logLevel = ZPLogLevelDebug;
    _logFilePath = @"/tmp/zooba_proto.log";
    _logToConsole = YES;
    _logToFile = NO;
    
    // ========== DUMP SETTINGS ==========
    _dumpInterval = 5.0;           // 5 seconds
    _maxTokensToStore = 100;
    _clearOldTokensOnLaunch = NO;
    
    // ========== TARGET SETTINGS ==========
    _targetBundleID = @"com.wildlife.games.battle.royale.free.zooba";
    _targetProcessName = @"Zooba";
    _wildlifeClassPrefixes = @[
        @"WL",
        @"Wildlife",
        @"WLNetwork",
        @"WLGame",
        @"WLAuth",
        @"WLPlayer",
        @"WLSession",
        @"WLSProtocol"
    ];
    _pitayaClassPrefixes = @[
        @"Pitaya",
        @"PitayaClient",
        @"PitayaNetwork",
        @"PitayaSession",
        @"PitayaMessage"
    ];
    _tokenKeyPatterns = @[
        @"token",
        @"auth",
        @"session",
        @"access",
        @"bearer",
        @"credential",
        @"Wildlife",
        @"Pitaya",
        @"player",
        @"user"
    ];
    _authHeaderPatterns = @[
        @"Authorization",
        @"X-Auth-Token",
        @"X-Access-Token",
        @"Auth-Token",
        @"Bearer",
        @"Token"
    ];
    
    // ========== UI SETTINGS ==========
    _uiPanelTitle = @"🎯 ZoobaProto";
    _showNotificationOnToken = YES;
    _vibrateOnToken = YES;
    _playSoundOnToken = NO;
    
    // ========== STORAGE SETTINGS ==========
    _storageBackend = ZPStorageBackendFile;
    _tokenSavePath = @"/tmp/zooba_tokens.json";
    
    NSLog(@"[ZoobaProto/Config] Defaults loaded");
}

- (void)resetToDefaults {
    NSLog(@"[ZoobaProto/Config] Resetting to defaults...");
    
    // Remove saved config
    NSString *path = [self configFilePath];
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    
    // Reload defaults
    [self loadDefaults];
}

#pragma mark - File Operations

- (NSString *)configFilePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = paths.firstObject;
    return [documentsPath stringByAppendingPathComponent:kConfigFileName];
}

- (void)saveToFile {
    @try {
        NSString *path = [self configFilePath];
        
        NSMutableDictionary *config = [NSMutableDictionary dictionary];
        
        // Version info
        config[@"_configVersion"] = kConfigVersion;
        config[@"_savedAt"] = @([[NSDate date] timeIntervalSince1970]);
        
        // Features
        config[@"enableTokenDump"] = @(self.enableTokenDump);
        config[@"enableNetworkHook"] = @(self.enableNetworkHook);
        config[@"enablePitayaHook"] = @(self.enablePitayaHook);
        config[@"enableKeychainDump"] = @(self.enableKeychainDump);
        config[@"enableFileLogging"] = @(self.enableFileLogging);
        config[@"notifyOnToken"] = @(self.notifyOnToken);
        config[@"autoSaveToken"] = @(self.autoSaveToken);
        config[@"enableUIPanel"] = @(self.enableUIPanel);
        config[@"enablePeriodicDump"] = @(self.enablePeriodicDump);
        
        // Logging
        config[@"logLevel"] = @(self.logLevel);
        config[@"logFilePath"] = self.logFilePath ?: @"";
        config[@"logToConsole"] = @(self.logToConsole);
        config[@"logToFile"] = @(self.logToFile);
        
        // Dump
        config[@"dumpInterval"] = @(self.dumpInterval);
        config[@"maxTokensToStore"] = @(self.maxTokensToStore);
        config[@"clearOldTokensOnLaunch"] = @(self.clearOldTokensOnLaunch);
        
        // UI
        config[@"showNotificationOnToken"] = @(self.showNotificationOnToken);
        config[@"vibrateOnToken"] = @(self.vibrateOnToken);
        config[@"playSoundOnToken"] = @(self.playSoundOnToken);
        
        // Storage
        config[@"storageBackend"] = @(self.storageBackend);
        config[@"tokenSavePath"] = self.tokenSavePath ?: @"";
        
        NSError *error;
        NSData *data = [NSJSONSerialization dataWithJSONObject:config 
                                                      options:NSJSONWritingPrettyPrinted 
                                                        error:&error];
        
        if (!error && data) {
            [data writeToFile:path atomically:YES];
            NSLog(@"[ZoobaProto/Config] Config saved to: %@", path);
        } else {
            NSLog(@"[ZoobaProto/Config] Failed to save config: %@", error.localizedDescription);
        }
    } @catch (NSException *exception) {
        NSLog(@"[ZoobaProto/Config] Exception saving config: %@", exception.reason);
    }
}

- (void)loadFromFile {
    @try {
        NSString *path = [self configFilePath];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
            NSLog(@"[ZoobaProto/Config] No saved config found, using defaults");
            return;
        }
        
        NSData *data = [NSData dataWithContentsOfFile:path];
        if (!data) {
            NSLog(@"[ZoobaProto/Config] Config file is empty");
            return;
        }
        
        NSError *error;
        NSDictionary *config = [NSJSONSerialization JSONObjectWithData:data 
                                                            options:0 
                                                              error:&error];
        
        if (error || ![config isKindOfClass:[NSDictionary class]]) {
            NSLog(@"[ZoobaProto/Config] Failed to parse config: %@", error.localizedDescription);
            return;
        }
        
        // Check version
        NSString *version = config[@"_configVersion"];
        if (version && ![version isEqualToString:kConfigVersion]) {
            NSLog(@"[ZoobaProto/Config] Config version mismatch: %@ vs %@", version, kConfigVersion);
        }
        
        // ========== APPLY CONFIG ==========
        
        // Features
        if (config[@"enableTokenDump"]) _enableTokenDump = [config[@"enableTokenDump"] boolValue];
        if (config[@"enableNetworkHook"]) _enableNetworkHook = [config[@"enableNetworkHook"] boolValue];
        if (config[@"enablePitayaHook"]) _enablePitayaHook = [config[@"enablePitayaHook"] boolValue];
        if (config[@"enableKeychainDump"]) _enableKeychainDump = [config[@"enableKeychainDump"] boolValue];
        if (config[@"enableFileLogging"]) _enableFileLogging = [config[@"enableFileLogging"] boolValue];
        if (config[@"notifyOnToken"]) _notifyOnToken = [config[@"notifyOnToken"] boolValue];
        if (config[@"autoSaveToken"]) _autoSaveToken = [config[@"autoSaveToken"] boolValue];
        if (config[@"enableUIPanel"]) _enableUIPanel = [config[@"enableUIPanel"] boolValue];
        if (config[@"enablePeriodicDump"]) _enablePeriodicDump = [config[@"enablePeriodicDump"] boolValue];
        
        // Logging
        if (config[@"logLevel"]) _logLevel = [config[@"logLevel"] integerValue];
        if (config[@"logFilePath"]) _logFilePath = config[@"logFilePath"];
        if (config[@"logToConsole"]) _logToConsole = [config[@"logToConsole"] boolValue];
        if (config[@"logToFile"]) _logToFile = [config[@"logToFile"] boolValue];
        
        // Dump
        if (config[@"dumpInterval"]) _dumpInterval = [config[@"dumpInterval"] doubleValue];
        if (config[@"maxTokensToStore"]) _maxTokensToStore = [config[@"maxTokensToStore"] unsignedIntegerValue];
        if (config[@"clearOldTokensOnLaunch"]) _clearOldTokensOnLaunch = [config[@"clearOldTokensOnLaunch"] boolValue];
        
        // UI
        if (config[@"showNotificationOnToken"]) _showNotificationOnToken = [config[@"showNotificationOnToken"] boolValue];
        if (config[@"vibrateOnToken"]) _vibrateOnToken = [config[@"vibrateOnToken"] boolValue];
        if (config[@"playSoundOnToken"]) _playSoundOnToken = [config[@"playSoundOnToken"] boolValue];
        
        // Storage
        if (config[@"storageBackend"]) _storageBackend = [config[@"storageBackend"] integerValue];
        if (config[@"tokenSavePath"]) _tokenSavePath = config[@"tokenSavePath"];
        
        NSLog(@"[ZoobaProto/Config] Config loaded from: %@", path);
        
    } @catch (NSException *exception) {
        NSLog(@"[ZoobaProto/Config] Exception loading config: %@", exception.reason);
    }
}

#pragma mark - Feature Flags

- (BOOL)isFeatureEnabled:(ZPFeatureFlags)flag {
    switch (flag) {
        case ZPFeatureTokenDump: return self.enableTokenDump;
        case ZPFeatureNetworkHook: return self.enableNetworkHook;
        case ZPFeaturePitayaHook: return self.enablePitayaHook;
        case ZPFeatureKeychainDump: return self.enableKeychainDump;
        case ZPFeatureFileLogging: return self.enableFileLogging;
        case ZPFeatureNotifyToken: return self.notifyOnToken;
        case ZPFeatureAutoSave: return self.autoSaveToken;
        case ZPFeatureUIPanel: return self.enableUIPanel;
        case ZPFeaturePeriodicDump: return self.enablePeriodicDump;
        default: return NO;
    }
}

- (void)setFeature:(ZPFeatureFlags)flag enabled:(BOOL)enabled {
    switch (flag) {
        case ZPFeatureTokenDump: _enableTokenDump = enabled; break;
        case ZPFeatureNetworkHook: _enableNetworkHook = enabled; break;
        case ZPFeaturePitayaHook: _enablePitayaHook = enabled; break;
        case ZPFeatureKeychainDump: _enableKeychainDump = enabled; break;
        case ZPFeatureFileLogging: _enableFileLogging = enabled; break;
        case ZPFeatureNotifyToken: _notifyOnToken = enabled; break;
        case ZPFeatureAutoSave: _autoSaveToken = enabled; break;
        case ZPFeatureUIPanel: _enableUIPanel = enabled; break;
        case ZPFeaturePeriodicDump: _enablePeriodicDump = enabled; break;
    }
    
    // Auto-save on change
    [self saveToFile];
}

#pragma mark - Validation

- (BOOL)validateConfig {
    NSString *errors = [self configValidationErrors];
    return errors.length == 0;
}

- (NSString *)configValidationErrors {
    NSMutableArray *errors = [NSMutableArray array];
    
    // Check dump interval
    if (self.dumpInterval < 1.0) {
        [errors addObject:@"dumpInterval must be >= 1 second"];
    }
    if (self.dumpInterval > 300.0) {
        [errors addObject:@"dumpInterval must be <= 300 seconds"];
    }
    
    // Check target bundle ID
    if (!self.targetBundleID || self.targetBundleID.length == 0) {
        [errors addObject:@"targetBundleID is required"];
    }
    
    // Check log file path
    if (self.logToFile && (!self.logFilePath || self.logFilePath.length == 0)) {
        [errors addObject:@"logFilePath is required when logToFile is enabled"];
    }
    
    // Check token patterns
    if (!self.tokenKeyPatterns || self.tokenKeyPatterns.count == 0) {
        [errors addObject:@"tokenKeyPatterns cannot be empty"];
    }
    
    // Check max tokens
    if (self.maxTokensToStore < 1) {
        [errors addObject:@"maxTokensToStore must be >= 1"];
    }
    if (self.maxTokensToStore > 10000) {
        [errors addObject:@"maxTokensToStore must be <= 10000"];
    }
    
    if (errors.count > 0) {
        return [errors componentsJoinedByString:@"; "];
    }
    return nil;
}

#pragma mark - Debug

- (NSDictionary *)dumpConfig {
    return @{
        @"version": kConfigVersion,
        @"features": @{
            @"enableTokenDump": @(self.enableTokenDump),
            @"enableNetworkHook": @(self.enableNetworkHook),
            @"enablePitayaHook": @(self.enablePitayaHook),
            @"enableKeychainDump": @(self.enableKeychainDump),
            @"enableFileLogging": @(self.enableFileLogging),
            @"notifyOnToken": @(self.notifyOnToken),
            @"autoSaveToken": @(self.autoSaveToken),
            @"enableUIPanel": @(self.enableUIPanel),
            @"enablePeriodicDump": @(self.enablePeriodicDump),
        },
        @"logging": @{
            @"logLevel": @(self.logLevel),
            @"logFilePath": self.logFilePath ?: @"",
            @"logToConsole": @(self.logToConsole),
            @"logToFile": @(self.logToFile),
        },
        @"dump": @{
            @"dumpInterval": @(self.dumpInterval),
            @"maxTokensToStore": @(self.maxTokensToStore),
            @"clearOldTokensOnLaunch": @(self.clearOldTokensOnLaunch),
        },
        @"target": @{
            @"bundleID": self.targetBundleID ?: @"",
            @"processName": self.targetProcessName ?: @"",
            @"wildlifePrefixesCount": @(self.wildlifeClassPrefixes.count),
            @"pitayaPrefixesCount": @(self.pitayaClassPrefixes.count),
            @"tokenPatternsCount": @(self.tokenKeyPatterns.count),
        },
        @"ui": @{
            @"panelTitle": self.uiPanelTitle ?: @"",
            @"showNotificationOnToken": @(self.showNotificationOnToken),
            @"vibrateOnToken": @(self.vibrateOnToken),
            @"playSoundOnToken": @(self.playSoundOnToken),
        },
        @"storage": @{
            @"backend": @(self.storageBackend),
            @"tokenSavePath": self.tokenSavePath ?: @"",
        }
    };
}

@end
