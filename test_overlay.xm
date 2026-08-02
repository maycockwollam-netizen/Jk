#import <UIKit/UIKit.h>
#import <substrate.h>

static UIWindow *overlayWindow = nil;

%hook UIApplication
- (BOOL)application:(UIApplication *)app didFinishLaunchingWithOptions:(NSDictionary *)opts {
    %orig;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        NSLog(@"[TestOverlay] Creating overlay...");
        
        overlayWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        overlayWindow.windowLevel = UIWindowLevelStatusBar + 1;
        overlayWindow.backgroundColor = [UIColor clearColor];
        
        UIViewController *vc = [[UIViewController alloc] init];
        overlayWindow.rootViewController = vc;
        
        // Big red button for testing
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(20, 100, 100, 100);
        btn.backgroundColor = [UIColor redColor];
        [btn setTitle:@"TEST" forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont boldSystemFontOfSize:20];
        btn.layer.cornerRadius = 50;
        
        [btn addTarget:self action:@selector(testButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        
        [vc.view addSubview:btn];
        [overlayWindow makeKeyAndVisible];
        
        NSLog(@"[TestOverlay] Button created!");
    });
    
    return YES;
}

%new
- (void)testButtonTapped {
    NSLog(@"[TestOverlay] Button tapped!");
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"TestOverlay"
                                                                   message:@"Button works!"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    
    UIViewController *topVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (topVC.presentedViewController) {
        topVC = topVC.presentedViewController;
    }
    [topVC presentViewController:alert animated:YES completion:nil];
}
%end
