//
//  ZPToast.m
//  ZoobaProto
//
//  Toast notification implementation
//

#import "ZPToast.h"
#import "ZPColors.h"
#import "ZPConstants.h"

@implementation ZPToast

+ (void)show:(NSString *)message {
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    if (window) {
        [self show:message inView:window];
    }
}

+ (void)show:(NSString *)message inView:(UIView *)view {
    ZPToast *toast = [[ZPToast alloc] initWithMessage:message];
    [view addSubview:toast];
    
    toast.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [toast.centerXAnchor constraintEqualToAnchor:view.centerXAnchor],
        [toast.bottomAnchor constraintEqualToAnchor:view.safeAreaLayoutGuide.bottomAnchor constant:-20]
    ]];
    
    // Animate in
    toast.alpha = 0;
    toast.transform = CGAffineTransformMakeScale(0.8, 0.8);
    
    [UIView animateWithDuration:ZPAnimationDurationMedium
                          delay:0
         usingSpringWithDamping:0.7
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
        toast.alpha = 1;
        toast.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        // Auto dismiss after 1.5 seconds
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:ZPAnimationDurationMedium animations:^{
                toast.alpha = 0;
                toast.transform = CGAffineTransformMakeScale(0.8, 0.8);
            } completion:^(BOOL finished) {
                [toast removeFromSuperview];
            }];
        });
    }];
}

- (instancetype)initWithMessage:(NSString *)message {
    self = [super init];
    if (self) {
        [self setupViewWithMessage:message];
    }
    return self;
}

- (void)setupViewWithMessage:(NSString *)message {
    self.backgroundColor = [ZPColors backgroundSecondary];
    self.layer.cornerRadius = 8;
    self.layer.borderWidth = 1;
    self.layer.borderColor = [[ZPColors accent] colorWithAlphaComponent:0.3].CGColor;
    
    UILabel *label = [[UILabel alloc] init];
    label.text = message;
    label.textColor = [ZPColors textPrimary];
    label.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    label.textAlignment = NSTextAlignmentCenter;
    label.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self addSubview:label];
    
    // Add accent tint bar on left
    UIView *tintBar = [[UIView alloc] init];
    tintBar.backgroundColor = [ZPColors accent];
    tintBar.layer.cornerRadius = 1;
    tintBar.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:tintBar];
    
    [NSLayoutConstraint activateConstraints:@[
        [label.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [label.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:16],
        [label.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-16],
        
        [tintBar.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:8],
        [tintBar.topAnchor constraintEqualToAnchor:self.topAnchor constant:8],
        [tintBar.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-8],
        [tintBar.widthAnchor constraintEqualToConstant:3],
        
        [self.heightAnchor constraintEqualToConstant:36],
        [self.widthAnchor constraintGreaterThanOrEqualToConstant:100]
    ]];
}

@end
