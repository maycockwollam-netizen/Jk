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

static UIWindow *_overlayWindow = nil;
static UIButton *_btn = nil;

+ (void)setup {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (_overlayWindow) {
            ZPLogInfo(@"Window already exists");
            return;
        }
        
        ZPLogInfo(@"Creating overlay window...");
        
        // Create new window at highest level
        _overlayWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _overlayWindow.windowLevel = UIWindowLevelAlert + 1; // Higher than everything
        _overlayWindow.backgroundColor = [UIColor clearColor];
        
        UIViewController *vc = [[UIViewController alloc] init];
        vc.view.backgroundColor = [UIColor clearColor];
        _overlayWindow.rootViewController = vc;
        
        // Create button
        CGFloat size = 70;
        CGFloat x = [UIScreen mainScreen].bounds.size.width - size - 20;
        
        _btn = [UIButton buttonWithType:UIButtonTypeCustom];
        _btn.frame = CGRectMake(x, 80, size, size);
        _btn.backgroundColor = [UIColor colorWithRed:0.0 green:0.6 blue:1.0 alpha:1.0];
        _btn.layer.cornerRadius = size / 2;
        _btn.layer.borderWidth = 4;
        _btn.layer.borderColor = [UIColor whiteColor].CGColor;
        _btn.layer.shadowColor = [UIColor blackColor].CGColor;
        _btn.layer.shadowOffset = CGSizeMake(0, 5);
        _btn.layer.shadowRadius = 12;
        _btn.layer.shadowOpacity = 0.6;
        
        [_btn setTitle:@"ZP" forState:UIControlStateNormal];
        [_btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _btn.titleLabel.font = [UIFont boldSystemFontOfSize:26];
        
        [_btn addTarget:[self class] action:@selector(tapped) forControlEvents:UIControlEventTouchUpInside];
        
        [vc.view addSubview:_btn];
        
        [_overlayWindow makeKeyAndVisible];
        
        ZPLogInfo(@"Overlay window created at level %f!", _overlayWindow.windowLevel);
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
            
            // Also save to file for easy reading
            NSString *logPath = @"/var/mobile/Documents/ZoobaProto/tokens.log";
            NSString *logEntry = [NSString stringWithFormat:@"%@: %@\n", [NSDate date], bearer];
            [[NSFileManager defaultManager] createDirectoryAtPath:@"/var/mobile/Documents/ZoobaProto/" withIntermediateDirectories:YES attributes:nil error:nil];
            NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:logPath];
            if (!fh) {
                [[NSData data] writeToFile:logPath atomically:YES];
                fh = [NSFileHandle fileHandleForWritingAtPath:logPath];
            }
            [fh seekToEndOfFile];
            [fh writeData:[logEntry dataUsingEncoding:NSUTF8StringEncoding]];
            [fh closeFile];
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
