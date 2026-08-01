//
//  UIModule.mm
//  ZoobaProto
//
//  UI Module - Token viewer and settings panel
//

#import "UIModule.h"
#import "Config.h"
#import "StorageModule.h"
#import "UtilsModule.h"
#import <objc/runtime.h>

#define ZPLog(fmt, args...) NSLog(@"[ZoobaProto/UI] " fmt, ##args)

#pragma mark - ZPTokenCell

@implementation ZPTokenCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupViews];
    }
    return self;
}

- (void)setupViews {
    self.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.15 alpha:1.0];
    
    // Key Label
    _keyLabel = [[UILabel alloc] init];
    _keyLabel.font = [UIFont boldSystemFontOfSize:14];
    _keyLabel.textColor = [UIColor colorWithRed:0.3 green:0.7 blue:1.0 alpha:1.0];
    _keyLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_keyLabel];
    
    // Type Label
    _typeLabel = [[UILabel alloc] init];
    _typeLabel.font = [UIFont systemFontOfSize:10];
    _typeLabel.textColor = [UIColor grayColor];
    _typeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_typeLabel];
    
    // Value Label
    _valueLabel = [[UILabel alloc] init];
    _valueLabel.font = [UIFont systemFontOfSize:12];
    _valueLabel.textColor = [UIColor whiteColor];
    _valueLabel.numberOfLines = 2;
    _valueLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_valueLabel];
    
    // Copy Button
    _copyButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_copyButton setTitle:@"📋" forState:UIControlStateNormal];
    _copyButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_copyButton addTarget:self action:@selector(copyTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:_copyButton];
    
    // Constraints
    [NSLayoutConstraint activateConstraints:@[
        [_keyLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:8],
        [_keyLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
        
        [_typeLabel.centerYAnchor constraintEqualToAnchor:_keyLabel.centerYAnchor],
        [_typeLabel.leadingAnchor constraintEqualToAnchor:_keyLabel.trailingAnchor constant:8],
        
        [_copyButton.centerYAnchor constraintEqualToAnchor:_keyLabel.centerYAnchor],
        [_copyButton.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16],
        [_copyButton.widthAnchor constraintEqualToConstant:40],
        
        [_valueLabel.topAnchor constraintEqualToAnchor:_keyLabel.bottomAnchor constant:4],
        [_valueLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
        [_valueLabel.trailingAnchor constraintEqualToAnchor:_copyButton.leadingAnchor constant:-8],
        [_valueLabel.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-8],
    ]];
}

- (void)configureWithKey:(NSString *)key value:(NSString *)value type:(NSString *)type {
    _keyLabel.text = key;
    _valueLabel.text = [self truncateValue:value];
    _typeLabel.text = [NSString stringWithFormat:@"[%@]", type];
}

- (NSString *)truncateValue:(NSString *)value {
    if (value.length > 100) {
        return [[value substringToIndex:100] stringByAppendingString:@"..."];
    }
    return value;
}

- (void)copyTapped {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = _valueLabel.text;
    
    // Visual feedback
    [_copyButton setTitle:@"✅" forState:UIControlStateNormal];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self->_copyButton setTitle:@"📋" forState:UIControlStateNormal];
    });
}

@end

#pragma mark - ZPSettingsCell

@implementation ZPSettingsCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupViews];
    }
    return self;
}

- (void)setupViews {
    self.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.15 alpha:1.0];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    // Title Label
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.font = [UIFont boldSystemFontOfSize:16];
    _titleLabel.textColor = [UIColor whiteColor];
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_titleLabel];
    
    // Description Label
    _descLabel = [[UILabel alloc] init];
    _descLabel.font = [UIFont systemFontOfSize:12];
    _descLabel.textColor = [UIColor grayColor];
    _descLabel.numberOfLines = 2;
    _descLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_descLabel];
    
    // Toggle Switch
    _toggleSwitch = [[UISwitch alloc] init];
    _toggleSwitch.onTintColor = [UIColor colorWithRed:0.3 green:0.7 blue:1.0 alpha:1.0];
    _toggleSwitch.translatesAutoresizingMaskIntoConstraints = NO;
    [_toggleSwitch addTarget:self action:@selector(switchToggled) forControlEvents:UIControlEventValueChanged];
    [self.contentView addSubview:_toggleSwitch];
    
    // Constraints
    [NSLayoutConstraint activateConstraints:@[
        [_titleLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:12],
        [_titleLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
        [_titleLabel.trailingAnchor constraintEqualToAnchor:_toggleSwitch.leadingAnchor constant:-16],
        
        [_descLabel.topAnchor constraintEqualToAnchor:_titleLabel.bottomAnchor constant:4],
        [_descLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
        [_descLabel.trailingAnchor constraintEqualToAnchor:_toggleSwitch.leadingAnchor constant:-16],
        [_descLabel.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-12],
        
        [_toggleSwitch.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
        [_toggleSwitch.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16],
    ]];
}

- (void)configureWithTitle:(NSString *)title desc:(NSString *)desc isOn:(BOOL)isOn {
    _titleLabel.text = title;
    _descLabel.text = desc;
    _toggleSwitch.on = isOn;
}

- (void)switchToggled {
    // Post notification for setting change
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ZoobaProtoSettingChanged"
                                                        object:nil
                                                      userInfo:@{
                                                          @"title": _titleLabel.text ?: @"",
                                                          @"value": @(_toggleSwitch.on)
                                                      }];
}

@end

#pragma mark - ZPTokenViewController

@implementation ZPTokenViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _tokens = [NSMutableArray array];
    _isShowingSettings = NO;
    
    [self setupUI];
    [self setupNotifications];
}

- (void)setupUI {
    // Background
    self.view.backgroundColor = [UIColor colorWithRed:0.05 green:0.05 blue:0.1 alpha:1.0];
    
    // Header View
    _headerView = [[UIView alloc] init];
    _headerView.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.2 alpha:1.0];
    _headerView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_headerView];
    
    // Title Label
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.text = @"🎯 ZoobaProto";
    _titleLabel.font = [UIFont boldSystemFontOfSize:18];
    _titleLabel.textColor = [UIColor whiteColor];
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [_headerView addSubview:_titleLabel];
    
    // Settings Button
    _settingsButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_settingsButton setTitle:@"⚙️" forState:UIControlStateNormal];
    _settingsButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_settingsButton addTarget:self action:@selector(showSettings) forControlEvents:UIControlEventTouchUpInside];
    [_headerView addSubview:_settingsButton];
    
    // Proto Button
    _protoButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_protoButton setTitle:@"📄" forState:UIControlStateNormal];
    _protoButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_protoButton addTarget:self action:@selector(openProtoFilePicker) forControlEvents:UIControlEventTouchUpInside];
    [_protoButton setAccessibilityHint:@"Parse .proto file"];
    [_headerView addSubview:_protoButton];
    
    // Refresh Button
    _refreshButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_refreshButton setTitle:@"🔄" forState:UIControlStateNormal];
    _refreshButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_refreshButton addTarget:self action:@selector(refreshTapped) forControlEvents:UIControlEventTouchUpInside];
    [_headerView addSubview:_refreshButton];
    
    // Clear Button
    _clearButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_clearButton setTitle:@"🗑️" forState:UIControlStateNormal];
    _clearButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_clearButton addTarget:self action:@selector(clearTapped) forControlEvents:UIControlEventTouchUpInside];
    [_headerView addSubview:_clearButton];
    
    // Table View
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _tableView.backgroundColor = [UIColor clearColor];
    _tableView.separatorColor = [UIColor darkGrayColor];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [_tableView registerClass:[ZPTokenCell class] forCellReuseIdentifier:@"TokenCell"];
    [_tableView registerClass:[ZPSettingsCell class] forCellReuseIdentifier:@"SettingsCell"];
    [self.view addSubview:_tableView];
    
    // Layout
    [NSLayoutConstraint activateConstraints:@[
        [_headerView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [_headerView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_headerView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_headerView.heightAnchor constraintEqualToConstant:60],
        
        [_titleLabel.centerYAnchor constraintEqualToAnchor:_headerView.centerYAnchor],
        [_titleLabel.leadingAnchor constraintEqualToAnchor:_headerView.leadingAnchor constant:16],
        
        [_settingsButton.centerYAnchor constraintEqualToAnchor:_headerView.centerYAnchor],
        [_settingsButton.trailingAnchor constraintEqualToAnchor:_headerView.trailingAnchor constant:-16],
        [_settingsButton.widthAnchor constraintEqualToConstant:44],
        
        [_protoButton.centerYAnchor constraintEqualToAnchor:_headerView.centerYAnchor],
        [_protoButton.trailingAnchor constraintEqualToAnchor:_settingsButton.leadingAnchor constant:-4],
        [_protoButton.widthAnchor constraintEqualToConstant:44],
        
        [_refreshButton.centerYAnchor constraintEqualToAnchor:_headerView.centerYAnchor],
        [_refreshButton.trailingAnchor constraintEqualToAnchor:_protoButton.leadingAnchor constant:-4],
        [_refreshButton.widthAnchor constraintEqualToConstant:44],
        
        [_clearButton.centerYAnchor constraintEqualToAnchor:_headerView.centerYAnchor],
        [_clearButton.trailingAnchor constraintEqualToAnchor:_refreshButton.leadingAnchor constant:-4],
        [_clearButton.widthAnchor constraintEqualToConstant:44],
        
        [_tableView.topAnchor constraintEqualToAnchor:_headerView.bottomAnchor],
        [_tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];
}

- (void)setupNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onTokenFound:)
                                                 name:@"ZoobaProtoTokenFound"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onSettingChanged:)
                                                 name:@"ZoobaProtoSettingChanged"
                                               object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Actions

- (void)refreshTapped {
    ZPLog(@"Refresh tapped");
    [self refreshTokens];
    
    // Visual feedback
    [_refreshButton setTitle:@"⏳" forState:UIControlStateNormal];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self->_refreshButton setTitle:@"🔄" forState:UIControlStateNormal];
    });
}

- (void)clearTapped {
    ZPLog(@"Clear tapped");
    [self clearTokens];
    
    // Visual feedback
    [_clearButton setTitle:@"✅" forState:UIControlStateNormal];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self->_clearButton setTitle:@"🗑️" forState:UIControlStateNormal];
    });
}

- (void)openProtoFilePicker {
    ZPLog(@"Opening proto file picker...");
    
    // Import ProtoUI
    extern Class ProtoUIClass;
    
    // Try to call ProtoUI
    Class protoUIClass = NSClassFromString(@"ProtoUI");
    if (protoUIClass) {
        SEL sharedSEL = NSSelectorFromString(@"shared");
        if ([protoUIClass respondsToSelector:sharedSEL]) {
            id protoUI = [protoUIClass performSelector:sharedSEL];
            SEL pickerSEL = NSSelectorFromString(@"showProtoFilePicker");
            if ([protoUI respondsToSelector:pickerSEL]) {
                [protoUI performSelector:pickerSEL];
                ZPLog(@"ProtoUI file picker opened");
                return;
            }
        }
    }
    
    // Fallback: Show alert
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Proto File Parser"
                                                                   message:@"Choose a .proto file to parse.\n\nThe parser will extract all message definitions and save them to storage."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
    
    ZPLog(@"ProtoUI class not found - showing info alert");
}

#pragma mark - Data

- (void)addToken:(NSString *)key value:(NSString *)value type:(NSString *)type {
    NSDictionary *token = @{
        @"key": key ?: @"",
        @"value": value ?: @"",
        @"type": type ?: @"unknown"
    };
    
    [_tokens addObject:token];
    [_tableView reloadData];
    
    ZPLog(@"Added token: %@", key);
}

- (void)refreshTokens {
    // Clear and reload
    [_tokens removeAllObjects];
    
    // Get tokens from StorageModule
    // In real implementation, would call [[StorageModule shared] getAllTokens]
    
    // Add sample tokens for demo
    [_tokens addObject:@{@"key": @"wildlife_access_token", @"value": @"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...", @"type": @"JWT"}];
    [_tokens addObject:@{@"key": @"session_token", @"value": @"abc123xyz789...", @"type": @"Session"}];
    
    [_tableView reloadData];
}

- (void)clearTokens {
    [_tokens removeAllObjects];
    [_tableView reloadData];
    ZPLog(@"Tokens cleared");
}

#pragma mark - Notifications

- (void)onTokenFound:(NSNotification *)notification {
    NSString *token = notification.userInfo[@"token"];
    if (token) {
        [self addToken:@"Bearer Token" value:token type:@"Bearer"];
    }
}

- (void)onSettingChanged:(NSNotification *)notification {
    NSString *title = notification.userInfo[@"title"];
    BOOL value = [notification.userInfo[@"value"] boolValue];
    ZPLog(@"Setting changed: %@ = %@", title, value ? @"ON" : @"OFF");
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _tokens.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZPTokenCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TokenCell" forIndexPath:indexPath];
    
    if (indexPath.row < _tokens.count) {
        NSDictionary *token = _tokens[indexPath.row];
        [cell configureWithKey:token[@"key"]
                         value:token[@"value"]
                          type:token[@"type"]];
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.row < _tokens.count) {
        NSDictionary *token = _tokens[indexPath.row];
        
        // Copy to clipboard
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = token[@"value"];
        
        ZPLog(@"Copied token: %@", token[@"key"]);
    }
}

@end

#pragma mark - UIModule

@interface UIModule ()
@property (nonatomic, strong, readwrite, nullable) ZPTokenViewController *tokenViewController;
@property (nonatomic, readwrite) BOOL isPanelVisible;
@end

@implementation UIModule

+ (instancetype)shared {
    static UIModule *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[UIModule alloc] init];
    });
    return instance;
}

- (void)setup {
    ZPLog(@"Setting up UI module...");
    
    // Setup notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onTokenFound:)
                                                 name:@"ZoobaProtoTokenFound"
                                               object:nil];
    
    ZPLog(@"UI module ready");
}

- (void)teardown {
    ZPLog(@"Tearing down UI module...");
    
    [self hideTokenPanel];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Panel Management

- (void)showTokenPanel {
    if (_isPanelVisible) {
        ZPLog(@"Panel already visible");
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        ZPLog(@"Showing token panel...");
        
        // Create view controller
        self.tokenViewController = [[ZPTokenViewController alloc] init];
        
        // Present modally (or push if in navigation)
        UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
        
        if (rootVC) {
            [rootVC presentViewController:self.tokenViewController animated:YES completion:^{
                self.isPanelVisible = YES;
                ZPLog(@"Token panel shown");
            }];
        } else {
            ZPLog(@"No root view controller found");
        }
    });
}

- (void)hideTokenPanel {
    if (!_isPanelVisible || !_tokenViewController) {
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        ZPLog(@"Hiding token panel...");
        
        [self.tokenViewController dismissViewControllerAnimated:YES completion:^{
            self.tokenViewController = nil;
            self.isPanelVisible = NO;
            ZPLog(@"Token panel hidden");
        }];
    });
}

#pragma mark - Token Display

- (void)displayToken:(NSString *)token key:(NSString *)key {
    if (_tokenViewController) {
        [_tokenViewController addToken:key value:token type:@"Bearer"];
    } else {
        ZPLog(@"Token found but panel not visible: %@", key);
    }
}

- (void)displayTokens:(NSArray<NSDictionary *> *)tokens {
    if (_tokenViewController) {
        for (NSDictionary *token in tokens) {
            [_tokenViewController addToken:token[@"key"]
                                      value:token[@"value"]
                                       type:token[@"type"] ?: @"unknown"];
        }
    }
}

- (void)clearDisplay {
    if (_tokenViewController) {
        [_tokenViewController clearTokens];
    }
}

#pragma mark - Notifications

- (void)onTokenFound:(NSNotification *)notification {
    NSString *token = notification.userInfo[@"token"];
    if (token) {
        [self displayToken:token key:@"Bearer Token"];
    }
}

@end
