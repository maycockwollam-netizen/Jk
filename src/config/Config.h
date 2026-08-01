//
//  Config.h
//  ZoobaProto
//
//  Configuration management
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ZPLogLevel) {
    ZPLogLevelDebug = 0,
    ZPLogLevelInfo = 1,
    ZPLogLevelWarn = 2,
    ZPLogLevelError = 3
};

typedef NS_OPTIONS(NSUInteger, ZPFeatureFlags) {
    ZPFeatureTokenDump       = 1 << 0,
    ZPFeatureNetworkHook    = 1 << 1,
    ZPFeaturePitayaHook     = 1 << 2,
    ZPFeatureKeychainDump   = 1 << 3,
    ZPFeatureFileLogging    = 1 << 4,
    ZPFeatureNotifyToken    = 1 << 5,
    ZPFeatureAutoSave       = 1 << 6,
    ZPFeatureUIPanel        = 1 << 7,
    ZPFeaturePeriodicDump   = 1 << 8,
};

typedef NS_ENUM(NSInteger, ZPStorageBackend) {
    ZPStorageBackendUserDefaults = 0,
    ZPStorageBackendKeychain = 1,
    ZPStorageBackendFile = 2
};

@interface Config : NSObject

+ (instancetype)shared;

// ========== FEATURE FLAGS ==========

@property (nonatomic, assign) BOOL enableTokenDump;
@property (nonatomic, assign) BOOL enableNetworkHook;
@property (nonatomic, assign) BOOL enablePitayaHook;
@property (nonatomic, assign) BOOL enableKeychainDump;
@property (nonatomic, assign) BOOL enableFileLogging;
@property (nonatomic, assign) BOOL notifyOnToken;
@property (nonatomic, assign) BOOL autoSaveToken;
@property (nonatomic, assign) BOOL enableUIPanel;
@property (nonatomic, assign) BOOL enablePeriodicDump;

// ========== LOGGING ==========

@property (nonatomic, assign) ZPLogLevel logLevel;
@property (nonatomic, strong) NSString *logFilePath;
@property (nonatomic, assign) BOOL logToConsole;
@property (nonatomic, assign) BOOL logToFile;

// ========== DUMP SETTINGS ==========

@property (nonatomic, assign) NSTimeInterval dumpInterval;           // seconds
@property (nonatomic, assign) NSUInteger maxTokensToStore;
@property (nonatomic, assign) BOOL clearOldTokensOnLaunch;

// ========== TARGET SETTINGS ==========

@property (nonatomic, strong) NSString *targetBundleID;
@property (nonatomic, strong) NSString *targetProcessName;
@property (nonatomic, strong) NSArray<NSString *> *wildlifeClassPrefixes;
@property (nonatomic, strong) NSArray<NSString *> *pitayaClassPrefixes;
@property (nonatomic, strong) NSArray<NSString *> *tokenKeyPatterns;
@property (nonatomic, strong) NSArray<NSString *> *authHeaderPatterns;

// ========== UI SETTINGS ==========

@property (nonatomic, strong) NSString *uiPanelTitle;
@property (nonatomic, assign) BOOL showNotificationOnToken;
@property (nonatomic, assign) BOOL vibrateOnToken;
@property (nonatomic, assign) BOOL playSoundOnToken;

// ========== STORAGE SETTINGS ==========

@property (nonatomic, assign) ZPStorageBackend storageBackend;
@property (nonatomic, strong) NSString *tokenSavePath;

// ========== METHODS ==========

- (void)loadDefaults;
- (void)resetToDefaults;
- (void)saveToFile;
- (void)loadFromFile;
- (BOOL)isFeatureEnabled:(ZPFeatureFlags)flag;
- (void)setFeature:(ZPFeatureFlags)flag enabled:(BOOL)enabled;

// Validation
- (BOOL)validateConfig;
- (NSString *)configValidationErrors;

// Debug
- (NSDictionary *)dumpConfig;

@end

NS_ASSUME_NONNULL_END
