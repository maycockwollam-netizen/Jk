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
    ZPFeatureNetworkHook     = 1 << 1,
    ZPFeaturePitayaHook      = 1 << 2,
    ZPFeatureKeychainDump    = 1 << 3,
    ZPFeatureFileLogging     = 1 << 4,
    ZPFeatureNotifyToken     = 1 << 5,
    ZPFeatureAutoSave        = 1 << 6,
};

@interface Config : NSObject

+ (instancetype)shared;

// Feature Flags
@property (nonatomic, assign) BOOL enableTokenDump;
@property (nonatomic, assign) BOOL enableNetworkHook;
@property (nonatomic, assign) BOOL enablePitayaHook;
@property (nonatomic, assign) BOOL enableKeychainDump;
@property (nonatomic, assign) BOOL enableFileLogging;
@property (nonatomic, assign) BOOL notifyOnToken;
@property (nonatomic, assign) BOOL autoSaveToken;

// Logging
@property (nonatomic, assign) ZPLogLevel logLevel;
@property (nonatomic, strong) NSString *logFilePath;

// Dump Settings
@property (nonatomic, assign) BOOL enablePeriodicDump;
@property (nonatomic, assign) NSTimeInterval dumpInterval; // seconds

// Target Settings
@property (nonatomic, strong) NSString *targetBundleID;
@property (nonatomic, strong) NSArray<NSString *> *wildlifeClassPrefixes;
@property (nonatomic, strong) NSArray<NSString *> *tokenKeyPatterns;

// Methods
- (void)loadDefaults;
- (void)saveToFile;
- (void)loadFromFile;
- (BOOL)isFeatureEnabled:(ZPFeatureFlags)flag;
- (void)setFeature:(ZPFeatureFlags)flag enabled:(BOOL)enabled;

@end

NS_ASSUME_NONNULL_END
