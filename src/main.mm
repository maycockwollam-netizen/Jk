//
//  main.mm
//  ZoobaProto v2.1.1-minimal
//
//  Minimal token dumper - no hooks, no ProtoInterceptor
//

#import <UIKit/UIKit.h>
#import <substrate.h>
#import <objc/runtime.h>

#import "config/Config.h"
#import "modules/storage/StorageModule.h"
#import "modules/utils/UtilsModule.h"

#define ZPLog(fmt, args...) NSLog(@"[ZoobaProto] " fmt, ##args)
#define ZPLogInfo(fmt, args...) NSLog(@"[ZoobaProto][INFO] " fmt, ##args)
#define ZPLogError(fmt, args...) NSLog(@"[ZoobaProto][ERROR] " fmt, ##args)

static NSString * const kTargetBundleID = @"com.fungames.battleroyale";
static NSString * const kVersion = @"2.1.1-minimal";

static StorageModule *g_storageModule = nil;
static UtilsModule *g_utilsModule = nil;
static BOOL g_initialized = NO;

static void DoTokenDump() {
    @try {
        ZPLogInfo(@"Dumping tokens...");
        [g_storageModule dumpAllTokens];
        
        NSString *bearer = [g_storageModule findBearerToken];
        if (bearer) {
            ZPLog(@"");
            ZPLog(@"========================================");
            ZPLog(@"TOKEN FOUND!");
            ZPLog(@"Token: %@", [bearer substringToIndex:MIN(50, bearer.length)]);
            ZPLog(@"========================================");
            ZPLog(@"");
            
            if ([Config shared].autoSaveToken) {
                [g_storageModule saveToken:bearer];
            }
        } else {
            ZPLogInfo(@"No Bearer token found yet");
        }
    } @catch (NSException *e) {
        ZPLogError(@"Dump error: %@", e.reason);
    }
}

static void ScheduleNextDump() {
    NSTimeInterval interval = [Config shared].dumpInterval;
    if (interval < 5.0) interval = 10.0;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(interval * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        if (g_initialized) {
            DoTokenDump();
            ScheduleNextDump();
        }
    });
}

__attribute__((constructor))
static void ZoobaProtoInit() {
    ZPLog(@"ZoobaProto %@ - Loading...", kVersion);
    
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    if (![bundleID isEqualToString:kTargetBundleID]) {
        return;
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        if (g_initialized) return;
        g_initialized = YES;
        
        @try {
            ZPLogInfo(@"Initializing...");
            g_storageModule = [[StorageModule alloc] init];
            [g_storageModule setup];
            g_utilsModule = [[UtilsModule alloc] init];
            [g_utilsModule setup];
            ZPLogInfo(@"Modules ready!");
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)),
                           dispatch_get_main_queue(), ^{
                DoTokenDump();
                ScheduleNextDump();
            });
            
            ZPLog(@"ZoobaProto %@ loaded!", kVersion);
        } @catch (NSException *e) {
            ZPLogError(@"Init error: %@", e.reason);
        }
    });
}
