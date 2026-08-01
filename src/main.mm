//
//  main.mm
//  ZoobaProto v2.1.4
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
static NSString * const kVersion = @"2.1.4";

static StorageModule *g_storageModule = nil;
static UtilsModule *g_utilsModule = nil;
static UIModule *g_uiModule = nil;
static BOOL g_initialized = NO;

#pragma mark - Floating Button

@interface ZPFloatingButton : NSObject
+ (void)setup;
@end

@implementation ZPFloatingButton

static UIButton *_btn = nil;

+ (void)setup {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (_btn) {
            ZPLogInfo(@"Button already exists");
            return;
        }
        
        ZPLogInfo(@"Creating floating button...");
        
        NSArray *windows = [UIApplication sharedApplication].windows;
        ZPLogInfo(@"Found %lu windows", (unsigned long)windows.count);
        
        UIWindow *mainWindow = nil;
        for (UIWindow *w in windows) {
            if (w.windowLevel == UIWindowLevelNormal) {
                mainWindow = w;
                break;
            }
        }
        
        if (!mainWindow && windows.count > 0) {
            mainWindow = windows.firstObject;
        }
        
        if (!mainWindow) {
            ZPLogError(@"No window found!");
            return;
        }
        
        CGFloat size = 60;
        CGFloat x = [UIScreen mainScreen].bounds.size.width - size - 15;
        
        _btn = [UIButton buttonWithType:UIButtonTypeCustom];
        _btn.frame = CGRectMake(x, 150, size, size);
        _btn.backgroundColor = [UIColor colorWithRed:0.0 green:0.5 blue:1.0 alpha:1.0];
        _btn.layer.cornerRadius = size / 2;
        _btn.layer.borderWidth = 3;
        _btn.layer.borderColor = [UIColor whiteColor].CGColor;
        _btn.layer.shadowColor = [UIColor blackColor].CGColor;
        _btn.layer.shadowOffset = CGSizeMake(0, 4);
        _btn.layer.shadowRadius = 10;
        _btn.layer.shadowOpacity = 0.5;
        
        [_btn setTitle:@"ZP" forState:UIControlStateNormal];
        [_btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _btn.titleLabel.font = [UIFont boldSystemFontOfSize:22];
        
        [_btn addTarget:[self class] action:@selector(tapped) forControlEvents:UIControlEventTouchUpInside];
        
        [mainWindow addSubview:_btn];
        
        ZPLogInfo(@"Floating button added!");
    });
}

+ (void)tapped {
    ZPLogInfo(@"Button tapped!");
    if (g_uiModule) {
        [g_uiModule showTokenPanel];
    }
}

@end

#pragma mark - Functions

static void DoDump() {
    @try {
        [g_storageModule dumpAllTokens];
        NSString *bearer = [g_storageModule findBearerToken];
        if (bearer) {
            ZPLog(@"========== TOKEN FOUND ==========");
            ZPLog(@"%@", [bearer substringToIndex:MIN(40, bearer.length)]);
            ZPLog(@"================================");
            if ([Config shared].autoSaveToken) {
                [g_storageModule saveToken:bearer];
            }
            if (g_uiModule) {
                [g_uiModule displayToken:bearer key:@"Bearer"];
            }
        }
    } @catch (NSException *e) {
        ZPLogError(@"Dump error: %@", e.reason);
    }
}

static void ScheduleDump() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        if (g_initialized) {
            DoDump();
            ScheduleDump();
        }
    });
}

#pragma mark - Entry Point

__attribute__((constructor))
static void Init() {
    ZPLog(@"ZoobaProto %@ loading...", kVersion);
    
    if (![[[NSBundle mainBundle] bundleIdentifier] isEqualToString:kTargetBundleID]) {
        return;
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (g_initialized) return;
        g_initialized = YES;
        
        @try {
            g_storageModule = [[StorageModule alloc] init];
            [g_storageModule setup];
            
            g_utilsModule = [[UtilsModule alloc] init];
            [g_utilsModule setup];
            
            g_uiModule = [UIModule shared];
            [g_uiModule setup];
            
            [ZPFloatingButton setup];
            
            ZPLog(@"ZoobaProto %@ ready!", kVersion);
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)),
                           dispatch_get_main_queue(), ^{
                DoDump();
                ScheduleDump();
            });
            
        } @catch (NSException *e) {
            ZPLogError(@"Init error: %@", e.reason);
        }
    });
}
