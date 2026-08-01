//
//  ZPNetworkView.m
//  ZoobaProto
//
//  Network tab implementation
//

#import "ZPNetworkView.h"
#import "ZPColors.h"
#import "ZPConstants.h"
#import "ZPToast.h"

#pragma mark - Request Cell

@interface ZPRequestCell : UITableViewCell
@property (nonatomic, strong) UILabel *methodBadge;
@property (nonatomic, strong) UILabel *pathLabel;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UILabel *sizeLabel;
@property (nonatomic, strong) UILabel *timeLabel;
@end

@implementation ZPRequestCell

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
    
    // Method badge
    _methodBadge = [[UILabel alloc] init];
    _methodBadge.font = [UIFont systemFontOfSize:10 weight:UIFontWeightBold];
    _methodBadge.textColor = [UIColor whiteColor];
    _methodBadge.textAlignment = NSTextAlignmentCenter;
    _methodBadge.layer.cornerRadius = 4;
    _methodBadge.layer.masksToBounds = YES;
    _methodBadge.translatesAutoresizingMaskIntoConstraints = NO;
    [cardView addSubview:_methodBadge];
    
    // Path
    _pathLabel = [[UILabel alloc] init];
    _pathLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    _pathLabel.textColor = [ZPColors textPrimary];
    _pathLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [cardView addSubview:_pathLabel];
    
    // Status
    _statusLabel = [[UILabel alloc] init];
    _statusLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    _statusLabel.textAlignment = NSTextAlignmentRight;
    _statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [cardView addSubview:_statusLabel];
    
    // Size & Time (secondary info)
    UIStackView *infoStack = [[UIStackView alloc] init];
    infoStack.axis = UILayoutConstraintAxisHorizontal;
    infoStack.spacing = 8;
    infoStack.translatesAutoresizingMaskIntoConstraints = NO;
    [cardView addSubview:infoStack];
    
    _sizeLabel = [[UILabel alloc] init];
    _sizeLabel.font = [UIFont systemFontOfSize:11];
    _sizeLabel.textColor = [ZPColors textSecondary];
    [infoStack addArrangedSubview:_sizeLabel];
    
    _timeLabel = [[UILabel alloc] init];
    _timeLabel.font = [UIFont systemFontOfSize:11];
    _timeLabel.textColor = [ZPColors textSecondary];
    [infoStack addArrangedSubview:_timeLabel];
    
    [NSLayoutConstraint activateConstraints:@[
        [cardView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:8],
        [cardView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-8],
        [cardView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:4],
        [cardView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-4],
        
        [_methodBadge.leadingAnchor constraintEqualToAnchor:cardView.leadingAnchor constant:10],
        [_methodBadge.topAnchor constraintEqualToAnchor:cardView.topAnchor constant:10],
        [_methodBadge.widthAnchor constraintEqualToConstant:42],
        [_methodBadge.heightAnchor constraintEqualToConstant:18],
        
        [_pathLabel.leadingAnchor constraintEqualToAnchor:_methodBadge.trailingAnchor constant:8],
        [_pathLabel.centerYAnchor constraintEqualToAnchor:_methodBadge.centerYAnchor],
        [_pathLabel.trailingAnchor constraintLessThanOrEqualToAnchor:_statusLabel.leadingAnchor constant:-8],
        
        [_statusLabel.trailingAnchor constraintEqualToAnchor:cardView.trailingAnchor constant:-10],
        [_statusLabel.centerYAnchor constraintEqualToAnchor:_methodBadge.centerYAnchor],
        [_statusLabel.widthAnchor constraintGreaterThanOrEqualToConstant:32],
        
        [infoStack.leadingAnchor constraintEqualToAnchor:_methodBadge.leadingAnchor],
        [infoStack.topAnchor constraintEqualToAnchor:_methodBadge.bottomAnchor constant:6],
        [infoStack.bottomAnchor constraintLessThanOrEqualToAnchor:cardView.bottomAnchor constant:-10]
    ]];
}

- (void)configureWithRequest:(NSDictionary *)request {
    NSString *method = request[@"method"] ?: @"GET";
    _methodBadge.text = method;
    _pathLabel.text = request[@"path"] ?: @"/";
    _sizeLabel.text = request[@"size"] ?: @"0 B";
    _timeLabel.text = request[@"time"] ?: @"";
    
    NSInteger status = [request[@"status"] integerValue];
    _statusLabel.text = [@(status) stringValue];
    
    // Method colors
    if ([method isEqualToString:@"POST"]) {
        _methodBadge.backgroundColor = [ZPColors methodPOST];
    } else if ([method isEqualToString:@"GET"]) {
        _methodBadge.backgroundColor = [ZPColors methodGET];
    } else {
        _methodBadge.backgroundColor = [ZPColors textSecondary];
    }
    
    // Status colors
    if (status >= 200 && status < 300) {
        _statusLabel.textColor = [ZPColors methodGET];
    } else if (status == 401 || status == 403) {
        _statusLabel.textColor = [ZPColors methodError];
    } else if (status >= 400) {
        _statusLabel.textColor = [ZPColors methodError];
    } else {
        _statusLabel.textColor = [ZPColors textSecondary];
    }
}

@end

#pragma mark - Search Bar

@interface ZPSearchField : UIView
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) UIButton *filterButton;
@end

@implementation ZPSearchField

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupView];
    }
    return self;
}

- (void)setupView {
    self.backgroundColor = [ZPColors backgroundTertiary];
    self.layer.cornerRadius = 8;
    self.translatesAutoresizingMaskIntoConstraints = NO;
    
    // Search icon
    UIImageView *searchIcon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"magnifyingglass"]];
    searchIcon.tintColor = [ZPColors textSecondary];
    searchIcon.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:searchIcon];
    
    // Text field
    _textField = [[UITextField alloc] init];
    _textField.placeholder = @"Search requests...";
    _textField.font = [UIFont systemFontOfSize:14];
    _textField.textColor = [ZPColors textPrimary];
    _textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Search requests..."
                                                                      attributes:@{NSForegroundColorAttributeName: [ZPColors textSecondary]}];
    _textField.returnKeyType = UIReturnKeySearch;
    _textField.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_textField];
    
    // Filter button
    _filterButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_filterButton setImage:[UIImage systemImageNamed:@"line.3.horizontal.decrease.circle"] forState:UIControlStateNormal];
    _filterButton.tintColor = [ZPColors textSecondary];
    _filterButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_filterButton];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.heightAnchor constraintEqualToConstant:36],
        
        [searchIcon.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:10],
        [searchIcon.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [searchIcon.widthAnchor constraintEqualToConstant:18],
        [searchIcon.heightAnchor constraintEqualToConstant:18],
        
        [_textField.leadingAnchor constraintEqualToAnchor:searchIcon.trailingAnchor constant:8],
        [_textField.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [_textField.trailingAnchor constraintEqualToAnchor:_filterButton.leadingAnchor constant:-8],
        
        [_filterButton.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-10],
        [_filterButton.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [_filterButton.widthAnchor constraintEqualToConstant:36],
        [_filterButton.heightAnchor constraintEqualToConstant:36]
    ]];
}

@end

#pragma mark - ZPNetworkView

@interface ZPNetworkView () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) ZPSearchField *searchField;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UILabel *emptyLabel;
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *requests;
@property (nonatomic, strong) NSArray<NSDictionary *> *filteredRequests;
@end

@implementation ZPNetworkView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _requests = [NSMutableArray array];
        _filteredRequests = @[];
        [self setupView];
    }
    return self;
}

- (void)setupView {
    // Search field
    _searchField = [[ZPSearchField alloc] init];
    _searchField.translatesAutoresizingMaskIntoConstraints = NO;
    _searchField.textField.delegate = (id<UITextFieldDelegate>)self;
    [self addSubview:_searchField];
    
    // Table view
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _tableView.backgroundColor = [UIColor clearColor];
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.rowHeight = 64;
    _tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [_tableView registerClass:[ZPRequestCell class] forCellReuseIdentifier:@"RequestCell"];
    [self addSubview:_tableView];
    
    // Empty state
    _emptyLabel = [[UILabel alloc] init];
    _emptyLabel.text = @"No requests captured yet.\nEnable recording to start.";
    _emptyLabel.numberOfLines = 0;
    _emptyLabel.textAlignment = NSTextAlignmentCenter;
    _emptyLabel.font = [UIFont systemFontOfSize:14];
    _emptyLabel.textColor = [ZPColors textSecondary];
    _emptyLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _emptyLabel.hidden = YES;
    [self addSubview:_emptyLabel];
    
    [NSLayoutConstraint activateConstraints:@[
        [_searchField.topAnchor constraintEqualToAnchor:self.topAnchor constant:8],
        [_searchField.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:12],
        [_searchField.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-12],
        
        [_tableView.topAnchor constraintEqualToAnchor:_searchField.bottomAnchor constant:8],
        [_tableView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [_tableView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [_tableView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        
        [_emptyLabel.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [_emptyLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [_emptyLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:32],
        [_emptyLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-32]
    ]];
}

- (void)addRequest:(NSDictionary *)request {
    [_requests addObject:request];
    _filteredRequests = [_requests copy];
    [_tableView reloadData];
    _emptyLabel.hidden = _requests.count > 0;
}

- (void)clearRequests {
    [_requests removeAllObjects];
    _filteredRequests = @[];
    [_tableView reloadData];
    _emptyLabel.hidden = NO;
}

- (void)refreshData {
    [_tableView reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _filteredRequests.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZPRequestCell *cell = [tableView dequeueReusableCellWithIdentifier:@"RequestCell" forIndexPath:indexPath];
    if (indexPath.row < _filteredRequests.count) {
        [cell configureWithRequest:_filteredRequests[indexPath.row]];
    }
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.row < _filteredRequests.count) {
        NSDictionary *request = _filteredRequests[indexPath.row];
        [self.delegate networkViewDidSelectRequest:request];
        
        // Haptic feedback
        UIImpactFeedbackGenerator *generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
        [generator impactOccurred];
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self filterRequests];
    });
    return YES;
}

- (void)filterRequests {
    NSString *searchText = _searchField.textField.text.lowercaseString;
    
    if (searchText.length == 0) {
        _filteredRequests = [_requests copy];
    } else {
        NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(NSDictionary *request, NSDictionary *bindings) {
            NSString *path = [request[@"path"] lowercaseString];
            NSString *method = [request[@"method"] lowercaseString];
            return [path containsString:searchText] || [method containsString:searchText];
        }];
        _filteredRequests = [_requests filteredArrayUsingPredicate:predicate];
    }
    
    [_tableView reloadData];
}

@end
