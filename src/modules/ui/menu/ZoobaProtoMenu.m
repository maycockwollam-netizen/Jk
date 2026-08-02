//
//  ZoobaProtoMenu.m
//  ZoobaProto
//
//  Main menu container implementation
//

#import "ZoobaProtoMenu.h"
#import "ZPColors.h"
#import "ZPConstants.h"
#import "ZPToast.h"
#import "ZPProtoView.h"
#import "ZPNetworkView.h"
#import "ZPSettingsView.h"

#pragma mark - Menu Bubble View

@interface ZPMenuBubble : UIView
@property (nonatomic, strong) UILabel *logoLabel;
@end

@implementation ZPMenuBubble

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupView];
    }
    return self;
}

- (void)setupView {
    self.backgroundColor = [ZPColors backgroundSecondary];
    self.layer.cornerRadius = ZPBubbleSize / 2;
    self.layer.borderWidth = ZPMenuBorderWidth;
    self.layer.borderColor = [ZPColors border].CGColor;

    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOffset = CGSizeMake(0, 4);
    self.layer.shadowRadius = 12;
    self.layer.shadowOpacity = 0.3;

    _logoLabel = [[UILabel alloc] init];
    _logoLabel.text = @"ZP";
    _logoLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightBold];
    _logoLabel.textColor = [ZPColors accent];
    _logoLabel.textAlignment = NSTextAlignmentCenter;
    _logoLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_logoLabel];

    [NSLayoutConstraint activateConstraints:@[
        [_logoLabel.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [_logoLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor]
    ]];
}

@end

#pragma mark - Menu Header View

@interface ZPMenuHeader : UIView
@property (nonatomic, strong) UILabel *logoIcon;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIView *recIndicator;
@property (nonatomic, strong) UILabel *recLabel;
@property (nonatomic, strong) UIButton *collapseButton;
@end

@implementation ZPMenuHeader

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupView];
    }
    return self;
}

- (void)setupView {
    self.backgroundColor = [UIColor clearColor];

    _logoIcon = [[UILabel alloc] init];
    _logoIcon.text = @"ZP";
    _logoIcon.font = [UIFont systemFontOfSize:12 weight:UIFontWeightBold];
    _logoIcon.textColor = [ZPColors accent];
    _logoIcon.textAlignment = NSTextAlignmentCenter;
    _logoIcon.backgroundColor = [[ZPColors accent] colorWithAlphaComponent:0.15];
    _logoIcon.layer.cornerRadius = 4;
    _logoIcon.layer.masksToBounds = YES;
    _logoIcon.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_logoIcon];

    _titleLabel = [[UILabel alloc] init];
    _titleLabel.text = @"ZoobaProto";
    _titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    _titleLabel.textColor = [ZPColors textPrimary];
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_titleLabel];

    UIView *recContainer = [[UIView alloc] init];
    recContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:recContainer];

    _recIndicator = [[UIView alloc] init];
    _recIndicator.backgroundColor = [ZPColors statusRecording];
    _recIndicator.layer.cornerRadius = 4;
    _recIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    [recContainer addSubview:_recIndicator];

    _recLabel = [[UILabel alloc] init];
    _recLabel.text = @"REC";
    _recLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
    _recLabel.textColor = [ZPColors statusRecording];
    _recLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [recContainer addSubview:_recLabel];

    _collapseButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_collapseButton setImage:[UIImage systemImageNamed:@"chevron.down"] forState:UIControlStateNormal];
    _collapseButton.tintColor = [ZPColors textSecondary];
    _collapseButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_collapseButton];

    UIView *spacer = [[UIView alloc] init];
    spacer.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:spacer];

    [NSLayoutConstraint activateConstraints:@[
        [self.heightAnchor constraintEqualToConstant:ZPHeaderHeight],
        [_logoIcon.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:12],
        [_logoIcon.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [_logoIcon.widthAnchor constraintEqualToConstant:28],
        [_logoIcon.heightAnchor constraintEqualToConstant:22],
        [_titleLabel.leadingAnchor constraintEqualToAnchor:_logoIcon.trailingAnchor constant:8],
        [_titleLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [spacer.leadingAnchor constraintEqualToAnchor:_titleLabel.trailingAnchor constant:8],
        [spacer.trailingAnchor constraintEqualToAnchor:recContainer.leadingAnchor constant:-8],
        [spacer.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [recContainer.trailingAnchor constraintEqualToAnchor:_collapseButton.leadingAnchor constant:-12],
        [recContainer.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [_recIndicator.leadingAnchor constraintEqualToAnchor:recContainer.leadingAnchor],
        [_recIndicator.centerYAnchor constraintEqualToAnchor:recContainer.centerYAnchor],
        [_recIndicator.widthAnchor constraintEqualToConstant:8],
        [_recIndicator.heightAnchor constraintEqualToConstant:8],
        [_recLabel.leadingAnchor constraintEqualToAnchor:_recIndicator.trailingAnchor constant:4],
        [_recLabel.trailingAnchor constraintEqualToAnchor:recContainer.trailingAnchor],
        [_recLabel.centerYAnchor constraintEqualToAnchor:recContainer.centerYAnchor],
        [_collapseButton.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-12],
        [_collapseButton.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [_collapseButton.widthAnchor constraintEqualToConstant:ZPMinimumTouchTarget],
        [_collapseButton.heightAnchor constraintEqualToConstant:ZPMinimumTouchTarget]
    ]];
}

- (void)setRecording:(BOOL)recording {
    _recIndicator.hidden = !recording;
    _recLabel.hidden = !recording;
}

@end

#pragma mark - Tab Bar View

@interface ZPTabBar : UIView
@property (nonatomic, strong) NSArray<UIButton *> *tabButtons;
@property (nonatomic, assign) NSInteger selectedIndex;
@end

@implementation ZPTabBar

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupView];
    }
    return self;
}

- (void)setupView {
    self.backgroundColor = [UIColor clearColor];

    NSArray *tabTitles = @[@"Network", @"Proto", @"Settings"];
    NSMutableArray *buttons = [NSMutableArray array];

    UIStackView *stackView = [[UIStackView alloc] init];
    stackView.axis = UILayoutConstraintAxisHorizontal;
    stackView.distribution = UIStackViewDistributionFillEqually;
    stackView.spacing = 4;
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:stackView];

    [NSLayoutConstraint activateConstraints:@[
        [stackView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:8],
        [stackView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-8],
        [stackView.topAnchor constraintEqualToAnchor:self.topAnchor constant:4],
        [stackView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-4],
        [self.heightAnchor constraintEqualToConstant:ZPTabBarHeight]
    ]];

    for (NSInteger i = 0; i < tabTitles.count; i++) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        [button setTitle:tabTitles[i] forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
        button.layer.cornerRadius = 6;
        button.tag = i;
        [stackView addArrangedSubview:button];
        [buttons addObject:button];
    }

    _tabButtons = [buttons copy];
    [self selectTab:0 animated:NO];
}

- (void)selectTab:(NSInteger)index animated:(BOOL)animated {
    for (NSInteger i = 0; i < _tabButtons.count; i++) {
        UIButton *button = _tabButtons[i];
        BOOL selected = (i == index);
        UIColor *bgColor = selected ? [[ZPColors accent] colorWithAlphaComponent:0.2] : [UIColor clearColor];
        UIColor *textColor = selected ? [ZPColors accent] : [ZPColors textSecondary];

        if (animated) {
            [UIView animateWithDuration:ZPAnimationDurationShort animations:^{
                button.backgroundColor = bgColor;
                button.tintColor = textColor;
                [button setTitleColor:textColor forState:UIControlStateNormal];
            }];
        } else {
            button.backgroundColor = bgColor;
            button.tintColor = textColor;
            [button setTitleColor:textColor forState:UIControlStateNormal];
        }
    }
    _selectedIndex = index;
}

@end

#pragma mark - ZoobaProtoMenu

@interface ZoobaProtoMenu () <UIGestureRecognizerDelegate>
@property (nonatomic, strong) UIWindow *overlayWindow;
@property (nonatomic, strong) UIView *dimmedBackground;
@property (nonatomic, strong) UIView *menuContainer;
@property (nonatomic, strong) ZPMenuBubble *bubble;
@property (nonatomic, strong) ZPMenuHeader *header;
@property (nonatomic, strong) ZPTabBar *tabBar;
@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;

// Bug #3 fix - Content container and tab views
@property (nonatomic, strong) UIView *contentContainer;
@property (nonatomic, strong) ZPProtoView *protoView;
@property (nonatomic, strong) ZPNetworkView *networkView;
@property (nonatomic, strong) ZPSettingsView *settingsView;
@end

@implementation ZoobaProtoMenu

+ (instancetype)shared {
    static ZoobaProtoMenu *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ZoobaProtoMenu alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _menuState = ZPMenuStateCollapsed;
        _currentTab = ZPTabTypeNetwork;
        _recording = NO;
        [self setupWindow];
    }
    return self;
}

- (void)setupWindow {
    _overlayWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    _overlayWindow.windowLevel = UIWindowLevelStatusBar - 1;
    _overlayWindow.backgroundColor = [UIColor clearColor];

    _dimmedBackground = [[UIView alloc] initWithFrame:_overlayWindow.bounds];
    _dimmedBackground.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
    _dimmedBackground.alpha = 0;
    UITapGestureRecognizer *tapBg = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissMenu)];
    [_dimmedBackground addGestureRecognizer:tapBg];

    _menuContainer = [[UIView alloc] init];
    _menuContainer.backgroundColor = [ZPColors backgroundSecondary];
    _menuContainer.layer.cornerRadius = ZPMenuCornerRadius;
    _menuContainer.layer.borderWidth = ZPMenuBorderWidth;
    _menuContainer.layer.borderColor = [ZPColors border].CGColor;
    _menuContainer.layer.masksToBounds = NO;
    _menuContainer.clipsToBounds = NO;
    _menuContainer.layer.shadowColor = [UIColor blackColor].CGColor;
    _menuContainer.layer.shadowOffset = CGSizeMake(0, -4);
    _menuContainer.layer.shadowRadius = 16;
    _menuContainer.layer.shadowOpacity = 0.25;

    _header = [[ZPMenuHeader alloc] init];
    [_menuContainer addSubview:_header];

    _tabBar = [[ZPTabBar alloc] init];
    [_menuContainer addSubview:_tabBar];

    // Bug #3 fix - Create content container and tab views
    _contentContainer = [[UIView alloc] init];
    _contentContainer.clipsToBounds = YES;
    [_menuContainer addSubview:_contentContainer];

    _protoView = [[ZPProtoView alloc] init];
    _networkView = [[ZPNetworkView alloc] init];
    _settingsView = [[ZPSettingsView alloc] init];

    _protoView.hidden = YES;
    _settingsView.hidden = YES;
    _networkView.hidden = NO;

    for (UIView *v in @[_protoView, _networkView, _settingsView]) {
        v.translatesAutoresizingMaskIntoConstraints = NO;
        [_contentContainer addSubview:v];
        [NSLayoutConstraint activateConstraints:@[
            [v.topAnchor constraintEqualToAnchor:_contentContainer.topAnchor],
            [v.leadingAnchor constraintEqualToAnchor:_contentContainer.leadingAnchor],
            [v.trailingAnchor constraintEqualToAnchor:_contentContainer.trailingAnchor],
            [v.bottomAnchor constraintEqualToAnchor:_contentContainer.bottomAnchor],
        ]];
    }

    _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    _panGesture.delegate = self;
    [_menuContainer addGestureRecognizer:_panGesture];

    [_header.collapseButton addTarget:self action:@selector(collapseMenu) forControlEvents:UIControlEventTouchUpInside];

    for (UIButton *button in _tabBar.tabButtons) {
        [button addTarget:self action:@selector(tabButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    }

    _bubble = [[ZPMenuBubble alloc] initWithFrame:CGRectMake(0, 0, ZPBubbleSize, ZPBubbleSize)];
    UITapGestureRecognizer *tapBubble = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(expandMenu)];
    [_bubble addGestureRecognizer:tapBubble];

    UIPanGestureRecognizer *bubblePan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleBubblePan:)];
    [_bubble addGestureRecognizer:bubblePan];

    [_overlayWindow addSubview:_dimmedBackground];
    [_overlayWindow addSubview:_menuContainer];
    [_overlayWindow addSubview:_bubble];

    _bubble.hidden = NO;
    _menuContainer.hidden = YES;
}

- (void)show {
    _overlayWindow.hidden = NO;
    _overlayWindow.rootViewController = [[UIViewController alloc] init];
    [_overlayWindow makeKeyAndVisible];
    [self expandMenu];
}

- (void)hide {
    [UIView animateWithDuration:ZPAnimationDurationMedium animations:^{
        self->_bubble.alpha = 0;
        self->_menuContainer.alpha = 0;
    } completion:^(BOOL finished) {
        [self->_overlayWindow setHidden:YES];
    }];
}

- (void)toggle {
    if (_menuState == ZPMenuStateCollapsed) {
        [self expandMenu];
    } else {
        [self collapseMenu];
    }
}

- (void)expandMenu {
    if (_menuState == ZPMenuStateExpanded) return;

    _menuState = ZPMenuStateExpanded;
    _menuContainer.hidden = NO;
    _bubble.hidden = YES;

    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat menuWidth = screenWidth * 0.88;
    CGFloat menuHeight = 340;

    CGFloat x = (screenWidth - menuWidth) / 2;
    CGFloat y = [UIScreen mainScreen].bounds.size.height - menuHeight - [self safeAreaBottom] - 80;

    _menuContainer.frame = CGRectMake(x, y, menuWidth, menuHeight);
    _menuContainer.transform = CGAffineTransformMakeScale(0.9, 0.9);
    _menuContainer.alpha = 0;

    _header.frame = CGRectMake(0, 0, menuWidth, ZPHeaderHeight);
    _tabBar.frame = CGRectMake(0, ZPHeaderHeight, menuWidth, ZPTabBarHeight + 8);

    UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(0, ZPHeaderHeight + ZPTabBarHeight + 8, menuWidth, 1)];
    separator.backgroundColor = [ZPColors border];
    separator.tag = 100;
    [_menuContainer addSubview:separator];

    // Bug #3 fix - Set content container frame
    CGFloat contentY = ZPHeaderHeight + ZPTabBarHeight + 8 + 1;
    _contentContainer.frame = CGRectMake(0, contentY, menuWidth, menuHeight - contentY);

    [UIView animateWithDuration:ZPAnimationDurationMedium
                          delay:0
         usingSpringWithDamping:0.8
          initialSpringVelocity:0.3
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
        self->_menuContainer.transform = CGAffineTransformIdentity;
        self->_menuContainer.alpha = 1;
        self->_dimmedBackground.alpha = 1;
    } completion:^(BOOL finished) {
        // Bug #4 fix
        if ([self.delegate respondsToSelector:@selector(menuDidChangeState:)]) {
            [self.delegate menuDidChangeState:ZPMenuStateExpanded];
        }
    }];
}

- (void)collapseMenu {
    if (_menuState == ZPMenuStateCollapsed) return;

    _menuState = ZPMenuStateCollapsed;

    CGRect bubbleFrame = _bubble.frame;
    CGFloat centerX = [UIScreen mainScreen].bounds.size.width - ZPBubbleSize - 20;
    CGFloat centerY = [UIScreen mainScreen].bounds.size.height - ZPBubbleSize - [self safeAreaBottom] - 20;
    bubbleFrame.origin = CGPointMake(centerX, centerY);

    [UIView animateWithDuration:ZPAnimationDurationMedium
                          delay:0
         usingSpringWithDamping:0.8
          initialSpringVelocity:0.3
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
        self->_menuContainer.transform = CGAffineTransformMakeScale(0.5, 0.5);
        self->_menuContainer.alpha = 0;
        self->_dimmedBackground.alpha = 0;
        self->_bubble.frame = bubbleFrame;
        self->_bubble.hidden = NO;
        self->_bubble.alpha = 1;
    } completion:^(BOOL finished) {
        self->_menuContainer.hidden = YES;
        // Bug #4 fix
        if ([self.delegate respondsToSelector:@selector(menuDidChangeState:)]) {
            [self.delegate menuDidChangeState:ZPMenuStateCollapsed];
        }
    }];
}

- (void)dismissMenu {
    [self collapseMenu];
}

- (void)selectTab:(ZPTabType)tabType {
    _currentTab = tabType;

    NSInteger tabIndex;
    switch (tabType) {
        case ZPTabTypeNetwork: tabIndex = 0; break;
        case ZPTabTypeProto: tabIndex = 1; break;
        case ZPTabTypeSettings: tabIndex = 2; break;
        default: tabIndex = 0; break;
    }

    [_tabBar selectTab:tabIndex animated:YES];

    // Bug #3 fix - Show/hide correct view
    _protoView.hidden = (tabType != ZPTabTypeProto);
    _networkView.hidden = (tabType != ZPTabTypeNetwork);
    _settingsView.hidden = (tabType != ZPTabTypeSettings);

    if ([self.delegate respondsToSelector:@selector(menuDidSelectTab:)]) {
        [self.delegate menuDidSelectTab:tabType];
    }
}

- (void)setRecording:(BOOL)recording {
    _recording = recording;
    [_header setRecording:recording];
}

- (void)tabButtonTapped:(UIButton *)sender {
    ZPTabType tabType;
    switch (sender.tag) {
        case 0: tabType = ZPTabTypeNetwork; break;
        case 1: tabType = ZPTabTypeProto; break;
        case 2: tabType = ZPTabTypeSettings; break;
        default: tabType = ZPTabTypeNetwork; break;
    }
    [self selectTab:tabType];
    UIImpactFeedbackGenerator *generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
    [generator impactOccurred];
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    CGPoint translation = [gesture translationInView:_overlayWindow];
    CGPoint velocity = [gesture velocityInView:_overlayWindow];

    if (gesture.state == UIGestureRecognizerStateChanged) {
        CGRect frame = _menuContainer.frame;
        frame.origin.y += translation.y;
        _menuContainer.frame = frame;
        [gesture setTranslation:CGPointZero inView:_overlayWindow];
        CGFloat dragUp = -translation.y;
        _dimmedBackground.alpha = MAX(0, 1 - dragUp / 200);
    } else if (gesture.state == UIGestureRecognizerStateEnded) {
        if (velocity.y > 500 || translation.y > 100) {
            [self collapseMenu];
        }
    }
}

- (void)handleBubblePan:(UIPanGestureRecognizer *)gesture {
    CGPoint translation = [gesture translationInView:_overlayWindow];

    if (gesture.state == UIGestureRecognizerStateChanged) {
        CGRect frame = _bubble.frame;
        frame.origin.x += translation.x;
        frame.origin.y += translation.y;
        _bubble.frame = frame;
        [gesture setTranslation:CGPointZero inView:_overlayWindow];
    } else if (gesture.state == UIGestureRecognizerStateEnded) {
        CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
        CGFloat centerX = _bubble.frame.origin.x + ZPBubbleSize / 2;
        CGFloat targetX = (centerX < screenWidth / 2) ? 20 : screenWidth - ZPBubbleSize - 20;
        [UIView animateWithDuration:ZPAnimationDurationShort animations:^{
            CGRect f = self->_bubble.frame;
            f.origin.x = targetX;
            self->_bubble.frame = f;
        }];
    }
}

- (CGFloat)safeAreaBottom {
    if (@available(iOS 11.0, *)) {
        return [UIApplication sharedApplication].keyWindow.safeAreaInsets.bottom;
    }
    return 0;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

@end
