//
//  main.mm
//  ZoobaProto v2.1.3
//
//  Minimal token dumper with floating UI button
//

#import <UIKit/UIKit.h>
#import <substrate.h>
#import <objc/runtime.h>

#import "config/Config.h"
#import "modules/storage/StorageModule.h"
#import "modules/utils/UtilsModule.h"
#import "modules/ui/UIModule.h"

#define ZPLog(fmt, args...) NSLog(@"[ZoobaProto] " fmt, ##args)
#define ZPLogInfo(fmt, args...) NSLog(@"[ZoobaProto][INFO] " fmt, ##args)
#define ZPLogError(fmt, args...) NSLog(@"[ZoobaProto][ERROR] " fmt, ##args)

static NSString * const kTargetBundleID = @"com.fungames.battleroyale";
static NSString * const kVersion = @"2.1.3";

static StorageModule *g_storageModule = nil;
static UtilsModule *g_utilsModule = nil;
static UIModule *g_uiModule = nil;
static BOOL g_initialized = NO;

#pragma mark - Floating Button

@interface ZoobaProtoFloatingButton : NSObject
+ (void)create;
@end

@implementation ZoobaProtoFloatingButton

static UIButton *_button = nil;

+ (void)create {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_button) return;
        
        CGFloat btnSize = 50;
        CGFloat screenW = [UIScreen mainScreen].bounds.size.width;
        
        _button = [UIButton buttonWithType:UIButtonTypeCustom];
        _button.frame = CGRectMake(screenW - btnSize - 20, 100, btnSize, btnSize);
        _button.backgroundColor = [UIColor colorWithRed:0.2 green:0.4 blue:0.8 alpha:0.9];
        _button.layer.cornerRadius = btnSize / 2;
        _button.layer.shadowColor = [UIColor blackColor].CGColor;
        _button.layer.shadowOffset = CGSizeMake(0, 4);
        _button.layer.shadowRadius = 8;
        _button.layer.shadowOpacity = 0.3;
        
        [_button setTitle:@"ZP" forState:UIControlStateNormal];
        _button.titleLabel.font = [UIFont boldSystemFontOfSize:16];
        [_button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        
        [_button addTarget:[self class] action:@selector(onTap) forControlEvents:UIControlEventTouchUpInside];
        
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        if (window) {
            [window addSubview:_button];
            ZPLogInfo(@"Floating button created at top-right");
        }
    });
}

+ (void)onTap {
    ZPLogInfo(@"Floating button tapped!");
    if (g_uiModule) {
        [g_uiModule showTokenPanel];
    }
}

@end

#pragma mark - Token Dump Functions

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
            
            if (g_uiModule) {
                [g_uiModule displayToken:bearer key:@"Bearer"];
            }
        } else {
            ZPLogInfo(@"No Bearer token found");
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

#pragma mark - Entry Point

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
            ZPLogInfo(@"Initializing modules...");
            
            g_storageModule = [[StorageModule alloc] init];
            [g_storageModule setup];
            
            g_utilsModule = [[UtilsModule alloc] init];
            [g_utilsModule setup];
            
            g_uiModule = [UIModule shared];
            [g_uiModule setup];
            
            // Create floating button after short delay
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
                           dispatch_get_main_queue(), ^{
                [ZoobaProtoFloatingButton create];
            });
            
            ZPLogInfo(@"All modules ready!");
            
            // First dump after 5 seconds
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)),
                           dispatch_get_main_queue(), ^{
                DoTokenDump();
                ScheduleNextDump();
            });
            
            ZPLog(@"");
            ZPLog(@"ZoobaProto %@ loaded!", kVersion);
            ZPLog(@"Tap ZP button to open menu!");
            ZPLog(@"");
            
        } @catch (NSException *e) {
            ZPLogError(@"Init error: %@", e.reason);
        }
    });
}
