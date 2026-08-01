//
//  main.mm
//  ZoobaProto v2.2.0
//

#import <UIKit/UIKit.h>
#import <substrate.h>
#import <objc/runtime.h>

#import "config/Config.h"
#import "modules/storage/StorageModule.h"
#import "modules/utils/UtilsModule.h"

#define ZPLog(fmt, args...) NSLog(@"[ZoobaProto] " fmt, ##args)

static NSString * const kTargetBundleID = @"com.fungames.battleroyale";
static NSString * const kVersion = @"2.2.0";

static StorageModule *g_storage = nil;
static BOOL g_initialized = NO;

#pragma mark - Overlay Window

@interface ZPOverlay : UIWindow
@end

@implementation ZPOverlay

- (void)makeKeyAndVisible {
    ZPLog(@"Making overlay visible");
    [super makeKeyAndVisible];
}

@end

#pragma mark - Setup

static void SetupOverlay() {
    @autoreleasepool {
        ZPLog(@"Setting up overlay...");
        
        @try {
            CGRect screenBounds = [UIScreen mainScreen].bounds;
            
            // Create overlay window
            ZPOverlay *overlay = [[ZPOverlay alloc] initWithFrame:screenBounds];
            overlay.windowLevel = UIWindowLevelStatusBar + 1;
            overlay.backgroundColor = [UIColor clearColor];
            
            // Root view controller
            UIViewController *rootVC = [[UIViewController alloc] init];
            overlay.rootViewController = rootVC;
            
            // Button
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
            btn.frame = CGRectMake(screenBounds.size.width - 80, 60, 70, 70);
            btn.backgroundColor = [UIColor colorWithRed:0.1 green:0.4 blue:0.9 alpha:1.0];
            btn.layer.cornerRadius = 35;
            btn.layer.borderWidth = 3;
            btn.layer.borderColor = [UIColor whiteColor].CGColor;
            
            [btn setTitle:@"ZP" forState:UIControlStateNormal];
            [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            btn.titleLabel.font = [UIFont boldSystemFontOfSize:24];
            
            [btn addTarget:rootVC action:@selector(buttonTapped) forControlEvents:UIControlEventTouchUpInside];
            
            [rootVC.view addSubview:btn];
            
            [overlay makeKeyAndVisible];
            
            ZPLog(@"Overlay setup complete!");
            
        } @catch (NSException *e) {
            ZPLog(@"Setup error: %@", e.reason);
        }
    }
}

// Button action
@interface UIViewController (ZPAction)
- (void)buttonTapped;
@end

@implementation UIViewController (ZPAction)

- (void)buttonTapped {
    ZPLog(@"Button tapped!");
    
    @try {
        NSArray *tokens = nil;
        if (g_storage) {
            [g_storage dumpAllTokens];
            NSString *bearer = [g_storage findBearerToken];
            if (bearer) {
                ZPLog(@"TOKEN: %@", [bearer substringToIndex:MIN(50, bearer.length)]);
            }
        }
    } @catch (NSException *e) {
        ZPLog(@"Dump error: %@", e.reason);
    }
}

@end

#pragma mark - Entry Point

__attribute__((constructor))
static void ZoobaProtoInit() {
    ZPLog(@"ZoobaProto %@", kVersion);
    
    if (![[[NSBundle mainBundle] bundleIdentifier] isEqualToString:kTargetBundleID]) {
        return;
    }
    
    ZPLog(@"Target app detected, loading...");
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if (g_initialized) return;
        g_initialized = YES;
        
        @try {
            g_storage = [[StorageModule alloc] init];
            [g_storage setup];
            
            SetupOverlay();
            
            ZPLog(@"ZoobaProto %@ loaded!", kVersion);
            
        } @catch (NSException *e) {
            ZPLog(@"Init error: %@", e.reason);
        }
    });
}
