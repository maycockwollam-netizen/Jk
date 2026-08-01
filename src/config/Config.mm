//
//  Config.mm
//  ZoobaProto
//
//  Configuration management
//

#import "Config.h"

static NSString * const kConfigFileName = @"ZoobaProto.config";

@implementation Config

+ (instancetype)shared {
    static Config *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[Config alloc] init];
        [instance loadDefaults];
        [instance loadFromFile];
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
    // Features
    _enableTokenDump = YES;
    _enableNetworkHook = YES;
    _enablePitayaHook = YES;
    _enableKeychainDump = YES;
    _enableFileLogging = NO;
    _notifyOnToken = YES;
    _autoSaveToken = YES;
    
    // Logging
    _logLevel = ZPLogLevelDebug;
    _logFilePath = @"/tmp/zooba_proto.log";
    
    // Dump
    _enablePeriodicDump = YES;
    _dumpInterval = 5.0; // 5 seconds
    
    // Target
    _targetBundleID = @"com.wildlife.games.battle.royale.free.zooba";
    _wildlifeClassPrefixes = @[
        @"WL",
        @"Wildlife", 
        @"WLNetwork",
        @"WLGame",
        @"WLAuth",
        @"WLPlayer",
        @"WLSession",
        @"Pitaya"
    ];
    _tokenKeyPatterns = @[
        @"token",
        @"auth",
        @"session",
        @"access",
        @"bearer",
        @"credential",
        @"Wildlife",
        @"Pitaya"
    ];
}

#pragma mark - File Operations

- (NSString *)configFilePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = paths.firstObject;
    return [documentsPath stringByAppendingPathComponent:kConfigFileName];
}

- (void)saveToFile {
    NSString *path = [self configFilePath];
    NSDictionary *config = @{
        @"enableTokenDump": @(self.enableTokenDump),
        @"enableNetworkHook": @(self.enableNetworkHook),
        @"enablePitayaHook": @(self.enablePitayaHook),
        @"enableKeychainDump": @(self.enableKeychainDump),
        @"enableFileLogging": @(self.enableFileLogging),
        @"notifyOnToken": @(self.notifyOnToken),
        @"autoSaveToken": @(self.autoSaveToken),
        @"logLevel": @(self.logLevel),
        @"dumpInterval": @(self.dumpInterval),
        @"enablePeriodicDump": @(self.enablePeriodicDump)
    };
    
    NSError *error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:config options:NSJSONWritingPrettyPrinted error:&error];
    
    if (!error && data) {
        [data writeToFile:path atomically:YES];
    }
}

- (void)loadFromFile {
    NSString *path = [self configFilePath];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        return;
    }
    
    NSData *data = [NSData dataWithContentsOfFile:path];
    if (!data) return;
    
    NSError *error;
    NSDictionary *config = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    
    if (error || ![config isKindOfClass:[NSDictionary class]]) {
        return;
    }
    
    // Apply config
    if (config[@"enableTokenDump"]) self.enableTokenDump = [config[@"enableTokenDump"] boolValue];
    if (config[@"enableNetworkHook"]) self.enableNetworkHook = [config[@"enableNetworkHook"] boolValue];
    if (config[@"enablePitayaHook"]) self.enablePitayaHook = [config[@"enablePitayaHook"] boolValue];
    if (config[@"enableKeychainDump"]) self.enableKeychainDump = [config[@"enableKeychainDump"] boolValue];
    if (config[@"enableFileLogging"]) self.enableFileLogging = [config[@"enableFileLogging"] boolValue];
    if (config[@"notifyOnToken"]) self.notifyOnToken = [config[@"notifyOnToken"] boolValue];
    if (config[@"autoSaveToken"]) self.autoSaveToken = [config[@"autoSaveToken"] boolValue];
    if (config[@"logLevel"]) self.logLevel = [config[@"logLevel"] integerValue];
    if (config[@"dumpInterval"]) self.dumpInterval = [config[@"dumpInterval"] doubleValue];
    if (config[@"enablePeriodicDump"]) self.enablePeriodicDump = [config[@"enablePeriodicDump"] boolValue];
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
        default: return NO;
    }
}

- (void)setFeature:(ZPFeatureFlags)flag enabled:(BOOL)enabled {
    switch (flag) {
        case ZPFeatureTokenDump: self.enableTokenDump = enabled; break;
        case ZPFeatureNetworkHook: self.enableNetworkHook = enabled; break;
        case ZPFeaturePitayaHook: self.enablePitayaHook = enabled; break;
        case ZPFeatureKeychainDump: self.enableKeychainDump = enabled; break;
        case ZPFeatureFileLogging: self.enableFileLogging = enabled; break;
        case ZPFeatureNotifyToken: self.notifyOnToken = enabled; break;
        case ZPFeatureAutoSave: self.autoSaveToken = enabled; break;
    }
}

@end
