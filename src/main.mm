//
//  main.mm
//  ZoobaProto v2
//
//  Main entry point for Zooba token dumper
//

#import <UIKit/UIKit.h>
#import <substrate.h>
#import <objc/runtime.h>

// Config
#import "config/Config.h"

// Core
#import "modules/core/CoreModule.h"
#import "modules/storage/StorageModule.h"
#import "modules/network/NetworkModule.h"
#import "modules/utils/UtilsModule.h"
#import "modules/ui/UIModule.h"
#import "modules/proto/ProtoParser.h"
#import "modules/protointerceptor/ProtoInterceptor.h"

// Hooks
#import "hooks/WildlifeHooks.h"
#import "hooks/UnityHooks.h"

// NEW UI Menu
#import "modules/ui/menu/ZoobaProtoMenuModule.h"

// ========== LOGGING ==========

#define ZPLog(fmt, args...) NSLog(@"[ZoobaProto] " fmt, ##args)
#define ZPLogInfo(fmt, args...) NSLog(@"[ZoobaProto][INFO] " fmt, ##args)
#define ZPLogDebug(fmt, args...) NSLog(@"[ZoobaProto][DEBUG] " fmt, ##args)
#define ZPLogError(fmt, args...) NSLog(@"[ZoobaProto][ERROR] " fmt, ##args)

// ========== CONSTANTS ==========

static NSString * const kTargetBundleID = @"com.fungames.battleroyale";
static NSString * const kTargetProcessName = @"Zooba";
static NSString * const kVersion = @"2.1.0";
static NSString * const kBuildDate = @"2024-01-15";

// Forward declarations
static void SchedulePeriodicDump(void);

// ========== MODULE INSTANCES ==========

static CoreModule *g_coreModule = nil;
static StorageModule *g_storageModule = nil;
static NetworkModule *g_networkModule = nil;
static UtilsModule *g_utilsModule = nil;
static UIModule *g_uiModule = nil;
static ProtoInterceptor *g_protoInterceptor = nil;

// NEW UI Menu
static ZoobaProtoMenu *g_zoobaMenu = nil;

// ========== MODULE INITIALIZATION ==========

static void InitializeModules() {
    ZPLogInfo(@"Initializing ZoobaProto v%@ (Build: %@)", kVersion, kBuildDate);
    ZPLogInfo(@"Config: %@", [Config shared].targetBundleID);
    
    // Initialize core module
    g_coreModule = [[CoreModule alloc] init];
    [g_coreModule setup];
    
    // Initialize storage module
    g_storageModule = [[StorageModule alloc] init];
    [g_storageModule setup];
    
    // Initialize network module
    g_networkModule = [[NetworkModule alloc] init];
    [g_networkModule setup];
    
    // Initialize utils module
    g_utilsModule = [[UtilsModule alloc] init];
    [g_utilsModule setup];
    
    // Initialize UI module
    if ([Config shared].enableUIPanel) {
        g_uiModule = [UIModule shared];
        [g_uiModule setup];
        ZPLogInfo(@"UI module enabled");
        
        // Initialize NEW ZoobaProtoMenu
        g_zoobaMenu = [ZoobaProtoMenu shared];
        ZPLogInfo(@"ZoobaProtoMenu initialized");
    }
    
    // Initialize ProtoParser module
    [[ProtoParser shared] setup];
    ZPLogInfo(@"ProtoParser module enabled");
    
    // Initialize ProtoInterceptor (fishhook-based)
    g_protoInterceptor = [ProtoInterceptor shared];
    [g_protoInterceptor setup];
    ZPLogInfo(@"ProtoInterceptor module enabled");
    
    // Log config dump
    ZPLogDebug(@"Config dump: %@", [Config shared].dumpConfig);
    
    ZPLogInfo(@"All modules initialized");
}

// ========== HOOK INSTALLATION ==========

static void InstallHooks() {
    ZPLogInfo(@"Installing hooks...");
    
    // Validate config first
    if (![[Config shared] validateConfig]) {
        ZPLogError(@"Config validation failed: %@", [[Config shared] configValidationErrors]);
        return;
    }
    
    // Install Wildlife hooks
    if ([Config shared].enablePitayaHook) {
        [WildlifeHooks install];
    } else {
        ZPLogInfo(@"Pitaya hooks disabled");
    }
    
    // Install ProtoInterceptor hooks (fishhook for socket functions)
    [g_protoInterceptor installHooks];
    ZPLogInfo(@"ProtoInterceptor hooks installed");
    
    // Install Unity hooks
    [UnityHooks install];
    
    ZPLogInfo(@"All hooks installed");
}

// ========== TOKEN HANDLING ==========

static void OnTokenFound(NSString *token) {
    ZPLog(@"🎉 TOKEN FOUND!");
    ZPLog(@"Token: %@", [token substringToIndex:MIN(50, token.length)]);
    
    // Save token
    if ([Config shared].autoSaveToken) {
        [g_storageModule saveToken:token];
        ZPLogInfo(@"Token saved");
    }
    
    // Display in UI
    if (g_uiModule) {
        [g_uiModule displayToken:token key:@"Bearer"];
    }
    
    // Notify
    if ([Config shared].notifyOnToken) {
        [g_utilsModule notifyTokenFound:token];
    }
}

static void PerformInitialDump() {
    ZPLogInfo(@"Performing initial token dump...");
    
    @try {
        // Dump from storage
        [g_storageModule dumpAllTokens];
        
        // Check for Bearer token
        NSString *bearer = [g_storageModule findBearerToken];
        if (bearer) {
            OnTokenFound(bearer);
        } else {
            ZPLogInfo(@"No Bearer token found yet, will continue monitoring...");
        }
        
    } @catch (NSException *exception) {
        ZPLogError(@"Exception during token dump: %@", exception.reason);
    }
    
    // Schedule next dump if enabled
    if ([Config shared].enablePeriodicDump) {
        SchedulePeriodicDump();
    }
}

static void SchedulePeriodicDump() {
    NSTimeInterval interval = [Config shared].dumpInterval;
    
    ZPLogDebug(@"Scheduling periodic dump every %.0f seconds", interval);
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(interval * NSEC_PER_SEC)), 
                   dispatch_get_main_queue(), ^{
        
        @try {
            [g_storageModule dumpAllTokens];
            
            // Check for new Bearer token
            NSString *bearer = [g_storageModule findBearerToken];
            if (bearer) {
                OnTokenFound(bearer);
            }
            
        } @catch (NSException *exception) {
            ZPLogError(@"Exception during periodic dump: %@", exception.reason);
        }
        
        // Schedule next
        SchedulePeriodicDump();
    });
}

// ========== APP LIFECYCLE ==========

static void RegisterAppLifecycle() {
    // App became active
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
        ZPLogDebug(@"App became active");
        
        @try {
            [g_storageModule dumpAllTokens];
        } @catch (NSException *exception) {
            ZPLogError(@"Exception in app became active: %@", exception.reason);
        }
    }];
    
    // App will resign active
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillResignActiveNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
        ZPLogDebug(@"App will resign active");
    }];
    
    // App will terminate
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillTerminateNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
        ZPLogInfo(@"App will terminate, saving config...");
        [[Config shared] saveToFile];
    }];
    
    ZPLogDebug(@"App lifecycle registered");
}

// ========== ENTRY POINT ==========

static BOOL g_initialized = NO;

__attribute__((constructor))
static void ZoobaProtoInit() {
    ZPLog(@"");
    ZPLog(@"ZoobaProto v%@ - Loading...", kVersion);

    // Check bundle ID FIRST
    NSString *currentBundleID = [[NSBundle mainBundle] bundleIdentifier];
    ZPLogInfo(@"Bundle ID: %@", currentBundleID);

    if (currentBundleID && ![currentBundleID isEqualToString:kTargetBundleID]) {
        ZPLogDebug(@"Not target app (%@), skipping...", currentBundleID);
        return;
    }

    ZPLogInfo(@"Target app detected: %@", kTargetBundleID);

    // DELAY initialization until app is ready (prevents crash)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        if (g_initialized) return;
        g_initialized = YES;

        @try {
            InitializeModules();
            InstallHooks();
            RegisterAppLifecycle();

            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)),
                           dispatch_get_main_queue(), ^{
                PerformInitialDump();
            });

            ZPLog(@"ZoobaProto v%@ loaded successfully!", kVersion);
            ZPLog(@"Dump interval: %.0f seconds", [Config shared].dumpInterval);

        } @catch (NSException *exception) {
            ZPLogError(@"Fatal exception: %@", exception.reason);
        }
    });
}

