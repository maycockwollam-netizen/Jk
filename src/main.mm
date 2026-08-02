//
//  main.mm
//  ZoobaProto UI Overlay Only
//

#import <UIKit/UIKit.h>
#import <substrate.h>

#define ZPLog(fmt, args...) NSLog(@"[ZoobaProto] " fmt, ##args)

static NSString * const kVersion = @"1.0.0";

#pragma mark - Overlay Window

@interface ZPOverlay : UIWindow
@property (nonatomic, strong) UIButton *zpButton;
@end

@implementation ZPOverlay

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.windowLevel = UIWindowLevelStatusBar + 1;
        self.backgroundColor = [UIColor clearColor];
        
        UIViewController *vc = [[UIViewController alloc] init];
        vc.view.backgroundColor = [UIColor clearColor];
        self.rootViewController = vc;
        
        [self setupButtonInView:vc.view];
    }
    return self;
}

- (void)setupButtonInView:(UIView *)view {
    CGFloat size = 70;
    CGFloat x = [UIScreen mainScreen].bounds.size.width - size - 20;
    
    self.zpButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.zpButton.frame = CGRectMake(x, 80, size, size);
    self.zpButton.backgroundColor = [UIColor colorWithRed:0.1 green:0.5 blue:1.0 alpha:1.0];
    self.zpButton.layer.cornerRadius = size / 2;
    self.zpButton.layer.borderWidth = 4;
    self.zpButton.layer.borderColor = [UIColor whiteColor].CGColor;
    self.zpButton.layer.shadowColor = [UIColor blackColor].CGColor;
    self.zpButton.layer.shadowOffset = CGSizeMake(0, 3);
    self.zpButton.layer.shadowRadius = 8;
    self.zpButton.layer.shadowOpacity = 0.5;
    
    [self.zpButton setTitle:@"ZP" forState:UIControlStateNormal];
    [self.zpButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.zpButton.titleLabel.font = [UIFont boldSystemFontOfSize:26];
    
    [self.zpButton addTarget:self action:@selector(buttonTapped) forControlEvents:UIControlEventTouchUpInside];
    
    [view addSubview:self.zpButton];
    ZPLog(@"Button added to view");
}

- (void)buttonTapped {
    ZPLog(@"ZP Button tapped!");
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"ZoobaProto"
                                                                  message:@"UI Overlay Working!"
                                                           preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    
    UIViewController *topVC = self.rootViewController;
    while (topVC.presentedViewController) {
        topVC = topVC.presentedViewController;
    }
    [topVC presentViewController:alert animated:YES completion:nil];
}

@end

static ZPOverlay *g_overlay = nil;

#pragma mark - Entry Point

__attribute__((constructor))
static void ZoobaProtoInit() {
    ZPLog(@"ZoobaProto UI v%@ loading...", kVersion);
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if (g_overlay) return;
        
        ZPLog(@"Creating overlay...");
        
        @try {
            g_overlay = [[ZPOverlay alloc] initWithFrame:[UIScreen mainScreen].bounds];
            [g_overlay makeKeyAndVisible];
            
            ZPLog(@"Overlay ready!");
        } @catch (NSException *e) {
            ZPLog(@"Error: %@", e.reason);
        }
    });
}
