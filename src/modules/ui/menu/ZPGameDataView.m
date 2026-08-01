//
//  ZPGameDataView.m
//  ZoobaProto
//
//  Game Data tab implementation
//

#import "ZPGameDataView.h"
#import "ZPColors.h"
#import "ZPConstants.h"
#import "ZPToast.h"

#pragma mark - Data Card View

@interface ZPDataCard : UIView
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIStackView *contentStack;
@end

@implementation ZPDataCard

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupView];
    }
    return self;
}

- (void)setupView {
    self.backgroundColor = [ZPColors backgroundTertiary];
    self.layer.cornerRadius = 10;
    self.translatesAutoresizingMaskIntoConstraints = NO;
    
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    _titleLabel.textColor = [ZPColors textPrimary];
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_titleLabel];
    
    _contentStack = [[UIStackView alloc] init];
    _contentStack.axis = UILayoutConstraintAxisVertical;
    _contentStack.spacing = 6;
    _contentStack.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_contentStack];
    
    [NSLayoutConstraint activateConstraints:@[
        [_titleLabel.topAnchor constraintEqualToAnchor:self.topAnchor constant:12],
        [_titleLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:14],
        [_titleLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-14],
        
        [_contentStack.topAnchor constraintEqualToAnchor:_titleLabel.bottomAnchor constant:10],
        [_contentStack.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:14],
        [_contentStack.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-14],
        [_contentStack.bottomAnchor constraintLessThanOrEqualToAnchor:self.bottomAnchor constant:-12]
    ]];
}

- (void)addRowWithLabel:(NSString *)label value:(NSString *)value {
    UIView *row = [[UIView alloc] init];
    row.translatesAutoresizingMaskIntoConstraints = NO;
    
    UILabel *keyLabel = [[UILabel alloc] init];
    keyLabel.text = label;
    keyLabel.font = [UIFont systemFontOfSize:12];
    keyLabel.textColor = [ZPColors textSecondary];
    keyLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [row addSubview:keyLabel];
    
    UILabel *valLabel = [[UILabel alloc] init];
    valLabel.text = value;
    valLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    valLabel.textColor = [ZPColors textPrimary];
    valLabel.textAlignment = NSTextAlignmentRight;
    valLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [row addSubview:valLabel];
    
    [NSLayoutConstraint activateConstraints:@[
        [keyLabel.leadingAnchor constraintEqualToAnchor:row.leadingAnchor],
        [keyLabel.centerYAnchor constraintEqualToAnchor:row.centerYAnchor],
        [valLabel.trailingAnchor constraintEqualToAnchor:row.trailingAnchor],
        [valLabel.centerYAnchor constraintEqualToAnchor:row.centerYAnchor],
        [keyLabel.trailingAnchor constraintLessThanOrEqualToAnchor:valLabel.leadingAnchor constant:-8],
        [row.heightAnchor constraintEqualToConstant:22]
    ]];
    
    [_contentStack addArrangedSubview:row];
}

@end

#pragma mark - ZPGameDataView

@interface ZPGameDataView () <UIScrollViewDelegate>
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIStackView *cardsStack;
@property (nonatomic, strong) ZPDataCard *playerCard;
@property (nonatomic, strong) ZPDataCard *matchCard;
@property (nonatomic, strong) ZPDataCard *inventoryCard;
@property (nonatomic, strong) UILabel *emptyLabel;
@end

@implementation ZPGameDataView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupView];
    }
    return self;
}

- (void)setupView {
    // Scroll view
    _scrollView = [[UIScrollView alloc] init];
    _scrollView.showsVerticalScrollIndicator = YES;
    _scrollView.alwaysBounceVertical = YES;
    _scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_scrollView];
    
    // Stack view for cards
    _cardsStack = [[UIStackView alloc] init];
    _cardsStack.axis = UILayoutConstraintAxisVertical;
    _cardsStack.spacing = 12;
    _cardsStack.translatesAutoresizingMaskIntoConstraints = NO;
    [_scrollView addSubview:_cardsStack];
    
    // Player card
    _playerCard = [[ZPDataCard alloc] init];
    _playerCard.titleLabel.text = @"👤 Player";
    [_cardsStack addArrangedSubview:_playerCard];
    
    // Match card
    _matchCard = [[ZPDataCard alloc] init];
    _matchCard.titleLabel.text = @"🎮 Match History";
    [_cardsStack addArrangedSubview:_matchCard];
    
    // Inventory card
    _inventoryCard = [[ZPDataCard alloc] init];
    _inventoryCard.titleLabel.text = @"🎒 Inventory";
    [_cardsStack addArrangedSubview:_inventoryCard];
    
    // Empty state
    _emptyLabel = [[UILabel alloc] init];
    _emptyLabel.text = @"No game data available";
    _emptyLabel.textAlignment = NSTextAlignmentCenter;
    _emptyLabel.font = [UIFont systemFontOfSize:14];
    _emptyLabel.textColor = [ZPColors textSecondary];
    _emptyLabel.hidden = YES;
    _emptyLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_emptyLabel];
    
    [NSLayoutConstraint activateConstraints:@[
        [_scrollView.topAnchor constraintEqualToAnchor:self.topAnchor constant:8],
        [_scrollView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [_scrollView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [_scrollView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        
        [_cardsStack.topAnchor constraintEqualToAnchor:_scrollView.topAnchor constant:8],
        [_cardsStack.leadingAnchor constraintEqualToAnchor:_scrollView.leadingAnchor constant:12],
        [_cardsStack.trailingAnchor constraintEqualToAnchor:_scrollView.trailingAnchor constant:-12],
        [_cardsStack.bottomAnchor constraintEqualToAnchor:_scrollView.bottomAnchor constant:-8],
        [_cardsStack.widthAnchor constraintEqualToAnchor:_scrollView.widthAnchor constant:-24],
        
        [_emptyLabel.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [_emptyLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor]
    ]];
}

- (void)updatePlayerData:(NSDictionary *)playerData {
    [_playerCard.contentStack.arrangedSubviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    if (playerData) {
        [_playerCard addRowWithLabel:@"Player ID" value:playerData[@"id"] ?: @"-"];
        [_playerCard addRowWithLabel:@"Name" value:playerData[@"name"] ?: @"-"];
        [_playerCard addRowWithLabel:@"Level" value:[playerData[@"level"] stringValue] ?: @"-"];
        [_playerCard addRowWithLabel:@"Status" value:playerData[@"status"] ?: @"-"];
    } else {
        UILabel *noData = [[UILabel alloc] init];
        noData.text = @"No data";
        noData.font = [UIFont systemFontOfSize:12];
        noData.textColor = [ZPColors textSecondary];
        [_playerCard.contentStack addArrangedSubview:noData];
    }
}

- (void)updateMatchHistory:(NSArray *)matches {
    [_matchCard.contentStack.arrangedSubviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    if (matches.count > 0) {
        for (NSDictionary *match in matches) {
            NSString *result = match[@"result"] ?: @"-";
            NSString *time = match[@"time"] ?: @"";
            [_matchCard addRowWithLabel:match[@"id"] ?: @"Match" value:result];
        }
    } else {
        UILabel *noData = [[UILabel alloc] init];
        noData.text = @"No matches";
        noData.font = [UIFont systemFontOfSize:12];
        noData.textColor = [ZPColors textSecondary];
        [_matchCard.contentStack addArrangedSubview:noData];
    }
}

- (void)updateInventory:(NSArray *)items {
    [_inventoryCard.contentStack.arrangedSubviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    if (items.count > 0) {
        for (NSDictionary *item in items) {
            NSString *qty = [item[@"quantity"] stringValue] ?: @"1";
            [_inventoryCard addRowWithLabel:item[@"name"] ?: @"Item" value:qty];
        }
    } else {
        UILabel *noData = [[UILabel alloc] init];
        noData.text = @"Empty";
        noData.font = [UIFont systemFontOfSize:12];
        noData.textColor = [ZPColors textSecondary];
        [_inventoryCard.contentStack addArrangedSubview:noData];
    }
}

- (void)refreshData {
    // Refresh with mock or existing data
}

@end
