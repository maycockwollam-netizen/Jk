//
//  ZPSettingsView.m
//  ZoobaProto
//
//  Settings tab implementation
//

#import "ZPSettingsView.h"
#import "ZPColors.h"
#import "ZPConstants.h"
#import "ZPToast.h"

#pragma mark - Settings Cell

@interface ZPSettingsCell : UITableViewCell
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *descLabel;
@property (nonatomic, strong) UISwitch *toggleSwitch;
@property (nonatomic, strong) UIButton *actionButton;
@property (nonatomic, assign) BOOL isDestructive;
@end

@implementation ZPSettingsCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupViews];
    }
    return self;
}

- (void)setupViews {
    self.backgroundColor = [UIColor clearColor];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    UIView *cardView = [[UIView alloc] init];
    cardView.backgroundColor = [ZPColors backgroundTertiary];
    cardView.layer.cornerRadius = 8;
    cardView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:cardView];
    
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    _titleLabel.textColor = [ZPColors textPrimary];
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [cardView addSubview:_titleLabel];
    
    _descLabel = [[UILabel alloc] init];
    _descLabel.font = [UIFont systemFontOfSize:11];
    _descLabel.textColor = [ZPColors textSecondary];
    _descLabel.numberOfLines = 2;
    _descLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [cardView addSubview:_descLabel];
    
    _toggleSwitch = [[UISwitch alloc] init];
    _toggleSwitch.onTintColor = [ZPColors accent];
    _toggleSwitch.translatesAutoresizingMaskIntoConstraints = NO;
    [cardView addSubview:_toggleSwitch];
    
    _actionButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _actionButton.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    _actionButton.translatesAutoresizingMaskIntoConstraints = NO;
    _actionButton.hidden = YES;
    [cardView addSubview:_actionButton];
    
    [NSLayoutConstraint activateConstraints:@[
        [cardView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:8],
        [cardView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-8],
        [cardView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:4],
        [cardView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-4],
        
        [_titleLabel.topAnchor constraintEqualToAnchor:cardView.topAnchor constant:12],
        [_titleLabel.leadingAnchor constraintEqualToAnchor:cardView.leadingAnchor constant:14],
        [_titleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:_toggleSwitch.leadingAnchor constant:-12],
        
        [_descLabel.topAnchor constraintEqualToAnchor:_titleLabel.bottomAnchor constant:4],
        [_descLabel.leadingAnchor constraintEqualToAnchor:_titleLabel.leadingAnchor],
        [_descLabel.trailingAnchor constraintEqualToAnchor:_titleLabel.trailingAnchor],
        [_descLabel.bottomAnchor constraintLessThanOrEqualToAnchor:cardView.bottomAnchor constant:-12],
        
        [_toggleSwitch.trailingAnchor constraintEqualToAnchor:cardView.trailingAnchor constant:-14],
        [_toggleSwitch.centerYAnchor constraintEqualToAnchor:cardView.centerYAnchor],
        
        [_actionButton.trailingAnchor constraintEqualToAnchor:cardView.trailingAnchor constant:-14],
        [_actionButton.centerYAnchor constraintEqualToAnchor:cardView.centerYAnchor]
    ]];
}

- (void)configureAsToggleWithTitle:(NSString *)title desc:(NSString *)desc isOn:(BOOL)isOn {
    _titleLabel.text = title;
    _descLabel.text = desc;
    _toggleSwitch.on = isOn;
    _toggleSwitch.hidden = NO;
    _actionButton.hidden = YES;
    _titleLabel.textColor = [ZPColors textPrimary];
}

- (void)configureAsActionWithTitle:(NSString *)title desc:(NSString *)desc destructive:(BOOL)destructive {
    _titleLabel.text = title;
    _descLabel.text = desc;
    _toggleSwitch.hidden = YES;
    _actionButton.hidden = NO;
    _actionButton.accessibilityHint = title;
    _isDestructive = destructive;
    _titleLabel.textColor = destructive ? [ZPColors methodError] : [ZPColors textPrimary];
    [_actionButton setTitleColor:destructive ? [ZPColors methodError] : [ZPColors accent] forState:UIControlStateNormal];
}

@end

#pragma mark - Section Header

@interface ZPSectionHeader : UIView
@property (nonatomic, strong) UILabel *titleLabel;
@end

@implementation ZPSectionHeader

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupView];
    }
    return self;
}

- (void)setupView {
    self.backgroundColor = [UIColor clearColor];
    
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];
    _titleLabel.textColor = [ZPColors textSecondary];
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_titleLabel];
    
    [NSLayoutConstraint activateConstraints:@[
        [_titleLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:16],
        [_titleLabel.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-4],
        [self.heightAnchor constraintEqualToConstant:32]
    ]];
}

- (void)setTitle:(NSString *)title {
    _titleLabel.text = title.uppercaseString;
}

@end

#pragma mark - ZPSettingsView

@interface ZPSettingsView () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@end

@implementation ZPSettingsView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupView];
    }
    return self;
}

- (void)setupView {
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    _tableView.backgroundColor = [UIColor clearColor];
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.rowHeight = 70;
    _tableView.sectionHeaderHeight = 36;
    _tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [_tableView registerClass:[ZPSettingsCell class] forCellReuseIdentifier:@"SettingsCell"];
    [self addSubview:_tableView];
    
    [NSLayoutConstraint activateConstraints:@[
        [_tableView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [_tableView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [_tableView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [_tableView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
    ]];
}

- (void)updateSettings:(NSDictionary *)settings {
    [_tableView reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0: return 3; // General
        case 1: return 3; // Storage
        case 2: return 2; // About
        default: return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZPSettingsCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SettingsCell" forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    switch (indexPath.section) {
        case 0: // General
            switch (indexPath.row) {
                case 0:
                    [cell configureAsToggleWithTitle:@"Recording" desc:@"Capture network requests" isOn:YES];
                    [cell.toggleSwitch addTarget:self action:@selector(recordingToggled:) forControlEvents:UIControlEventValueChanged];
                    break;
                case 1:
                    [cell configureAsToggleWithTitle:@"Auto-scroll" desc:@"Scroll to new requests" isOn:YES];
                    [cell.toggleSwitch addTarget:self action:@selector(autoScrollToggled:) forControlEvents:UIControlEventValueChanged];
                    break;
                case 2:
                    [cell configureAsToggleWithTitle:@"Compact Mode" desc:@"Use smaller UI elements" isOn:NO];
                    [cell.toggleSwitch addTarget:self action:@selector(compactModeToggled:) forControlEvents:UIControlEventValueChanged];
                    break;
            }
            break;
            
        case 1: // Storage
            switch (indexPath.row) {
                case 0:
                    [cell configureAsActionWithTitle:@"Clear Logs" desc:@"Delete all captured requests" destructive:YES];
                    [cell.actionButton addTarget:self action:@selector(clearLogsTapped) forControlEvents:UIControlEventTouchUpInside];
                    break;
                case 1:
                    [cell configureAsActionWithTitle:@"Clear Proto Data" desc:@"Remove cached proto definitions" destructive:YES];
                    [cell.actionButton addTarget:self action:@selector(clearProtoTapped) forControlEvents:UIControlEventTouchUpInside];
                    break;
                case 2:
                    [cell configureAsActionWithTitle:@"Export Session" desc:@"Save current session to file" destructive:NO];
                    [cell.actionButton addTarget:self action:@selector(exportSessionTapped) forControlEvents:UIControlEventTouchUpInside];
                    break;
            }
            break;
            
        case 2: // About
            switch (indexPath.row) {
                case 0:
                    [cell configureAsToggleWithTitle:@"ZoobaProto" desc:@"Version 2.0.0" isOn:NO];
                    cell.toggleSwitch.hidden = YES;
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    break;
                case 1:
                    [cell configureAsToggleWithTitle:@"Build" desc:@"iOS 14.0+" isOn:NO];
                    cell.toggleSwitch.hidden = YES;
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    break;
            }
            break;
    }
    
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    ZPSectionHeader *header = [[ZPSectionHeader alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 36)];
    switch (section) {
        case 0: [header setTitle:@"General"]; break;
        case 1: [header setTitle:@"Storage"]; break;
        case 2: [header setTitle:@"About"]; break;
    }
    return header;
}

#pragma mark - Actions

- (void)recordingToggled:(UISwitch *)sender {
    [self.delegate settingsDidToggleRecording:sender.isOn];
    UIImpactFeedbackGenerator *generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
    [generator impactOccurred];
}

- (void)autoScrollToggled:(UISwitch *)sender {
    [self.delegate settingsDidToggleAutoScroll:sender.isOn];
}

- (void)compactModeToggled:(UISwitch *)sender {
    [self.delegate settingsDidToggleCompactMode:sender.isOn];
}

- (void)clearLogsTapped {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Clear Logs"
                                                                   message:@"Are you sure you want to delete all captured requests?"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Clear" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [self.delegate settingsDidClearLogs];
        [ZPToast show:@"Logs cleared"];
    }]];
    
    [[self findViewController] presentViewController:alert animated:YES completion:nil];
}

- (void)clearProtoTapped {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Clear Proto Data"
                                                                   message:@"Remove all cached proto definitions?"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Clear" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [self.delegate settingsDidClearProtoData];
        [ZPToast show:@"Proto data cleared"];
    }]];
    
    [[self findViewController] presentViewController:alert animated:YES completion:nil];
}

- (void)exportSessionTapped {
    [self.delegate settingsDidExportSession];
    [ZPToast show:@"Session exported"];
}

- (UIViewController *)findViewController {
    for (UIView *next = [self superview]; next; next = next.superview) {
        UIResponder *nextResponder = [next nextResponder];
        if ([nextResponder isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)nextResponder;
        }
    }
    return nil;
}

@end
