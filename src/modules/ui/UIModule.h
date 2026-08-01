//
//  UIModule.h
//  ZoobaProto
//
//  UI Module - Token viewer and settings panel
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZPTokenCell : UITableViewCell
@property (nonatomic, strong) UILabel *keyLabel;
@property (nonatomic, strong) UILabel *valueLabel;
@property (nonatomic, strong) UILabel *typeLabel;
@property (nonatomic, strong) UIButton *copyButton;
- (void)configureWithKey:(NSString *)key value:(NSString *)value type:(NSString *)type;
@end

@interface ZPSettingsCell : UITableViewCell
@property (nonatomic, strong) UISwitch *toggleSwitch;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *descLabel;
- (void)configureWithTitle:(NSString *)title desc:(NSString *)desc isOn:(BOOL)isOn;
@end

@interface ZPTokenViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *refreshButton;
@property (nonatomic, strong) UIButton *clearButton;
@property (nonatomic, strong) UIView *headerView;

@property (nonatomic, strong) NSMutableArray<NSDictionary *> *tokens;
@property (nonatomic, assign) BOOL isShowingSettings;

- (void)addToken:(NSString *)key value:(NSString *)value type:(NSString *)type;
- (void)refreshTokens;
- (void)clearTokens;
- (void)showSettings;
- (void)showTokens;

@end

@interface UIModule : NSObject

+ (instancetype)shared;

// Setup
- (void)setup;
- (void)teardown;

// UI Management
- (void)showTokenPanel;
- (void)hideTokenPanel;
- (void)updateTokenList;

// Token Display
- (void)displayToken:(NSString *)token key:(NSString *)key;
- (void)displayTokens:(NSArray<NSDictionary *> *)tokens;
- (void)clearDisplay;

// Notifications
- (void)onTokenFound:(NSString *)token;

// Status
@property (nonatomic, readonly) BOOL isPanelVisible;
@property (nonatomic, strong, readonly, nullable) ZPTokenViewController *tokenViewController;

@end

NS_ASSUME_NONNULL_END
