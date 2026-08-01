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

// Hooks
#import "hooks/WildlifeHooks.h"
#import "hooks/UnityHooks.h"

// ========== LOGGING ==========

#define ZPLog(fmt, args...) NSLog(@"[ZoobaProto] " fmt, ##args)
#define ZPLogInfo(fmt, args...) NSLog(@"[ZoobaProto][INFO] " fmt, ##args)
#define ZPLogDebug(fmt, args...) NSLog(@"[ZoobaProto][DEBUG] " fmt, ##args)
#define ZPLogError(fmt, args...) NSLog(@"[ZoobaProto][ERROR] " fmt, ##args)

// ========== CONSTANTS ==========

static NSString * const kTargetBundleID = @"com.wildlife.games.battle.royale.free.zooba";
static NSString * const kTargetProcessName = @"Zooba";

// ========== VERSION ==========

static NSString * const kVersion = @"2.0.0";
static NSString * const kBuildDate = @"2024-01-01";

// ========== MODULES ==========

static CoreModule *g_coreModule = nil;
static StorageModule *g_storageModule = nil;
static NetworkModule *g_networkModule = nil;
static UtilsModule *g_utilsModule = nil;

// ========== INITIALIZATION ==========

static void InitializeModules() {
    ZPLogInfo(@"Initializing ZoobaProto v%@ (Build: %@)", kVersion, kBuildDate);
    
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
    
    ZPLogInfo(@"All modules initialized");
}

static void InstallHooks() {
    ZPLogInfo(@"Installing hooks...");
    
    // Install Wildlife hooks
    [WildlifeHooks install];
    
    // Install Unity hooks
    [UnityHooks install];
    
    ZPLogInfo(@"All hooks installed");
}

static void ScheduleInitialDump() {
    ZPLogInfo(@"Scheduling initial token dump in 3 seconds...");
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        
        ZPLogInfo(@"Performing initial token dump...");
        
        // Dump from storage
        [g_storageModule dumpAllTokens];
        
        // Check for Bearer token
        NSString *bearer = [g_storageModule findBearerToken];
        if (bearer) {
            ZPLog(@"🎉 BEARER TOKEN FOUND!");
            ZPLog(@"Token: %@", bearer);
            
            // Save token
            if ([Config shared].autoSaveToken) {
                [g_storageModule saveToken:bearer];
            }
            
            // Notify
            if ([Config shared].notifyOnToken) {
                [g_utilsModule notifyTokenFound:bearer];
            }
        } else {
            ZPLogInfo(@"No Bearer token found yet, will continue monitoring...");
        }
        
        // Schedule next dump
        SchedulePeriodicDump();
    });
}

static void SchedulePeriodicDump() {
    if (![Config shared].enablePeriodicDump) return;
    
    NSTimeInterval interval = [Config shared].dumpInterval;
    
    ZPLogDebug(@"Scheduling periodic dump every %.0f seconds", interval);
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, interval * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [g_storageModule dumpAllTokens];
        SchedulePeriodicDump();
    });
}

// ========== LIFECYCLE ==========

__attribute__((constructor))
static void ZoobaProtoInit() {
    ZPLog(@"===============================================");
    ZPLog(@"  ZoobaProto v%@", kVersion);
    ZPLog(@"  Bearer Token Dumper for Zooba");
    ZPLog(@"  Target: %@", kTargetBundleID);
    ZPLog(@"===============================================");
    
    // Check if target app
    NSString *currentBundleID = [[NSBundle mainBundle] bundleIdentifier];
    
    if (currentBundleID && ![currentBundleID isEqualToString:kTargetBundleID]) {
        ZPLogDebug(@"Not target app, skipping...");
        return;
    }
    
    // Initialize
    InitializeModules();
    InstallHooks();
    ScheduleInitialDump();
    
    // Register for app lifecycle
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
        ZPLogDebug(@"App became active");
        [g_storageModule dumpAllTokens];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillResignActiveNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
        ZPLogDebug(@"App will resign active");
    }];
    
    ZPLog(@"ZoobaProto loaded successfully!");
    ZPLog(@"===============================================");
}
