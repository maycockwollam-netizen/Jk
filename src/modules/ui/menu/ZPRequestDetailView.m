//
//  ZPRequestDetailView.m
//  ZoobaProto
//
//  Request detail panel implementation
//

#import "ZPRequestDetailView.h"
#import "ZPColors.h"
#import "ZPConstants.h"
#import "ZPToast.h"

#pragma mark - Detail Row

@interface ZPDetailRow : UIView
@property (nonatomic, strong) UILabel *keyLabel;
@property (nonatomic, strong) UILabel *valueLabel;
@property (nonatomic, strong) UIButton *copyButton;
@end

@implementation ZPDetailRow

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupView];
    }
    return self;
}

- (void)setupView {
    _keyLabel = [[UILabel alloc] init];
    _keyLabel.font = [UIFont systemFontOfSize:11];
    _keyLabel.textColor = [ZPColors textSecondary];
    _keyLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_keyLabel];
    
    _valueLabel = [[UILabel alloc] init];
    _valueLabel.font = [UIFont systemFontOfSize:13];
    _valueLabel.textColor = [ZPColors textPrimary];
    _valueLabel.numberOfLines = 0;
    _valueLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_valueLabel];
    
    _copyButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_copyButton setImage:[UIImage systemImageNamed:@"doc.on.doc"] forState:UIControlStateNormal];
    _copyButton.tintColor = [ZPColors textSecondary];
    _copyButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_copyButton addTarget:self action:@selector(copyTapped) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_copyButton];
    
    [NSLayoutConstraint activateConstraints:@[
        [_keyLabel.topAnchor constraintEqualToAnchor:self.topAnchor],
        [_keyLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        
        [_valueLabel.topAnchor constraintEqualToAnchor:_keyLabel.bottomAnchor constant:4],
        [_valueLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [_valueLabel.trailingAnchor constraintEqualToAnchor:_copyButton.leadingAnchor constant:-8],
        [_valueLabel.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        
        [_copyButton.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [_copyButton.centerYAnchor constraintEqualToAnchor:_valueLabel.centerYAnchor],
        [_copyButton.widthAnchor constraintEqualToConstant:32],
        [_copyButton.heightAnchor constraintEqualToConstant:32]
    ]];
}

- (void)setKey:(NSString *)key value:(NSString *)value copyable:(BOOL)copyable {
    _keyLabel.text = key;
    _valueLabel.text = value;
    _copyButton.hidden = !copyable;
    _copyButton.accessibilityHint = value;
}

- (void)copyTapped {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = _valueLabel.accessibilityHint ?: _valueLabel.text;
    [ZPToast show:@"Copied"];
}

@end

#pragma mark - ZPRequestDetailView

@interface ZPRequestDetailView ()
@property (nonatomic, strong) UIView *container;
@property (nonatomic, strong) UIView *headerBar;
@property (nonatomic, strong) UILabel *methodBadge;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIStackView *contentStack;
@property (nonatomic, strong) UIView *divider;
@end

@implementation ZPRequestDetailView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupView];
    }
    return self;
}

- (void)setupView {
    self.backgroundColor = [ZPColors backgroundSecondary];
    self.layer.cornerRadius = 16;
    self.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    self.clipsToBounds = YES;
    
    // Header bar
    _headerBar = [[UIView alloc] init];
    _headerBar.backgroundColor = [ZPColors backgroundTertiary];
    _headerBar.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_headerBar];
    
    // Method badge
    _methodBadge = [[UILabel alloc] init];
    _methodBadge.font = [UIFont systemFontOfSize:10 weight:UIFontWeightBold];
    _methodBadge.textColor = [UIColor whiteColor];
    _methodBadge.textAlignment = NSTextAlignmentCenter;
    _methodBadge.layer.cornerRadius = 4;
    _methodBadge.layer.masksToBounds = YES;
    _methodBadge.translatesAutoresizingMaskIntoConstraints = NO;
    [_headerBar addSubview:_methodBadge];
    
    // Title
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    _titleLabel.textColor = [ZPColors textPrimary];
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [_headerBar addSubview:_titleLabel];
    
    // Close button
    _closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_closeButton setImage:[UIImage systemImageNamed:@"xmark"] forState:UIControlStateNormal];
    _closeButton.tintColor = [ZPColors textSecondary];
    _closeButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_closeButton addTarget:self action:@selector(closeTapped) forControlEvents:UIControlEventTouchUpInside];
    [_headerBar addSubview:_closeButton];
    
    // Scroll view
    _scrollView = [[UIScrollView alloc] init];
    _scrollView.alwaysBounceVertical = YES;
    _scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_scrollView];
    
    // Content stack
    _contentStack = [[UIStackView alloc] init];
    _contentStack.axis = UILayoutConstraintAxisVertical;
    _contentStack.spacing = 16;
    _contentStack.translatesAutoresizingMaskIntoConstraints = NO;
    [_scrollView addSubview:_contentStack];
    
    // Divider
    _divider = [[UIView alloc] init];
    _divider.backgroundColor = [ZPColors border];
    _divider.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_divider];
    
    [NSLayoutConstraint activateConstraints:@[
        [_headerBar.topAnchor constraintEqualToAnchor:self.topAnchor],
        [_headerBar.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [_headerBar.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [_headerBar.heightAnchor constraintEqualToConstant:48],
        
        [_methodBadge.leadingAnchor constraintEqualToAnchor:_headerBar.leadingAnchor constant:14],
        [_methodBadge.centerYAnchor constraintEqualToAnchor:_headerBar.centerYAnchor],
        [_methodBadge.widthAnchor constraintEqualToConstant:46],
        [_methodBadge.heightAnchor constraintEqualToConstant:20],
        
        [_titleLabel.leadingAnchor constraintEqualToAnchor:_methodBadge.trailingAnchor constant:10],
        [_titleLabel.centerYAnchor constraintEqualToAnchor:_headerBar.centerYAnchor],
        [_titleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:_closeButton.leadingAnchor constant:-10],
        
        [_closeButton.trailingAnchor constraintEqualToAnchor:_headerBar.trailingAnchor constant:-12],
        [_closeButton.centerYAnchor constraintEqualToAnchor:_headerBar.centerYAnchor],
        [_closeButton.widthAnchor constraintEqualToConstant:44],
        [_closeButton.heightAnchor constraintEqualToConstant:44],
        
        [_divider.topAnchor constraintEqualToAnchor:_headerBar.bottomAnchor],
        [_divider.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [_divider.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [_divider.heightAnchor constraintEqualToConstant:1],
        
        [_scrollView.topAnchor constraintEqualToAnchor:_divider.bottomAnchor],
        [_scrollView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [_scrollView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [_scrollView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        
        [_contentStack.topAnchor constraintEqualToAnchor:_scrollView.topAnchor constant:16],
        [_contentStack.leadingAnchor constraintEqualToAnchor:_scrollView.leadingAnchor constant:14],
        [_contentStack.trailingAnchor constraintEqualToAnchor:_scrollView.trailingAnchor constant:-14],
        [_contentStack.bottomAnchor constraintEqualToAnchor:_scrollView.bottomAnchor constant:-16],
        [_contentStack.widthAnchor constraintEqualToAnchor:_scrollView.widthAnchor constant:-28]
    ]];
}

- (void)showWithRequest:(NSDictionary *)request {
    // Clear existing rows
    [_contentStack.arrangedSubviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    NSString *method = request[@"method"] ?: @"GET";
    _methodBadge.text = method;
    _titleLabel.text = request[@"path"] ?: @"/";
    
    if ([method isEqualToString:@"POST"]) {
        _methodBadge.backgroundColor = [ZPColors methodPOST];
    } else if ([method isEqualToString:@"GET"]) {
        _methodBadge.backgroundColor = [ZPColors methodGET];
    } else {
        _methodBadge.backgroundColor = [ZPColors textSecondary];
    }
    
    // Add detail rows
    [self addDetailRow:@"Method" value:method copyable:YES];
    [self addDetailRow:@"Status" value:[request[@"status"] stringValue] copyable:YES];
    [self addDetailRow:@"URL" value:request[@"url"] ?: @"" copyable:YES];
    [self addDetailRow:@"Size" value:request[@"size"] ?: @"0 B" copyable:NO];
    [self addDetailRow:@"Duration" value:request[@"duration"] ?: @"-" copyable:NO];
    [self addDetailRow:@"Time" value:request[@"time"] ?: @"-" copyable:NO];
    
    // Headers section
    UILabel *headersTitle = [[UILabel alloc] init];
    headersTitle.text = @"Request Headers";
    headersTitle.font = [UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];
    headersTitle.textColor = [ZPColors textSecondary];
    [_contentStack addArrangedSubview:headersTitle];
    
    NSDictionary *headers = request[@"headers"] ?: @{};
    for (NSString *key in headers) {
        [self addDetailRow:key value:headers[key] copyable:YES];
    }
    
    // Show with animation
    self.transform = CGAffineTransformMakeTranslation(0, self.bounds.size.height);
    self.hidden = NO;
    
    [UIView animateWithDuration:ZPAnimationDurationMedium
                          delay:0
         usingSpringWithDamping:0.85
          initialSpringVelocity:0.3
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
        self.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (void)hide {
    [UIView animateWithDuration:ZPAnimationDurationShort animations:^{
        self.transform = CGAffineTransformMakeTranslation(0, self.bounds.size.height);
    } completion:^(BOOL finished) {
        self.hidden = YES;
        [self.delegate detailDidClose];
    }];
}

- (void)addDetailRow:(NSString *)key value:(NSString *)value copyable:(BOOL)copyable {
    ZPDetailRow *row = [[ZPDetailRow alloc] init];
    [row setKey:key value:value copyable:copyable];
    [_contentStack addArrangedSubview:row];
}

- (void)closeTapped {
    [self hide];
}

@end
