//
//  ZPProtoView.m
//  ZoobaProto
//
//  Proto tab implementation
//

#import "ZPProtoView.h"
#import "ZPColors.h"
#import "ZPConstants.h"
#import "ZPToast.h"

#pragma mark - Message Cell

@interface ZPProtoMessageCell : UITableViewCell
@property (nonatomic, strong) UILabel *iconLabel;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *fieldCountLabel;
@end

@implementation ZPProtoMessageCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupViews];
    }
    return self;
}

- (void)setupViews {
    self.backgroundColor = [UIColor clearColor];
    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    UIView *cardView = [[UIView alloc] init];
    cardView.backgroundColor = [ZPColors backgroundTertiary];
    cardView.layer.cornerRadius = 8;
    cardView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:cardView];
    
    _iconLabel = [[UILabel alloc] init];
    _iconLabel.text = @"📋";
    _iconLabel.font = [UIFont systemFontOfSize:16];
    _iconLabel.textAlignment = NSTextAlignmentCenter;
    _iconLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [cardView addSubview:_iconLabel];
    
    _nameLabel = [[UILabel alloc] init];
    _nameLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    _nameLabel.textColor = [ZPColors textPrimary];
    _nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [cardView addSubview:_nameLabel];
    
    _fieldCountLabel = [[UILabel alloc] init];
    _fieldCountLabel.font = [UIFont systemFontOfSize:11];
    _fieldCountLabel.textColor = [ZPColors textSecondary];
    _fieldCountLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [cardView addSubview:_fieldCountLabel];
    
    [NSLayoutConstraint activateConstraints:@[
        [cardView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:8],
        [cardView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-8],
        [cardView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:4],
        [cardView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-4],
        
        [_iconLabel.leadingAnchor constraintEqualToAnchor:cardView.leadingAnchor constant:12],
        [_iconLabel.centerYAnchor constraintEqualToAnchor:cardView.centerYAnchor],
        [_iconLabel.widthAnchor constraintEqualToConstant:28],
        
        [_nameLabel.leadingAnchor constraintEqualToAnchor:_iconLabel.trailingAnchor constant:10],
        [_nameLabel.centerYAnchor constraintEqualToAnchor:cardView.centerYAnchor constant:-8],
        
        [_fieldCountLabel.leadingAnchor constraintEqualToAnchor:_nameLabel.leadingAnchor],
        [_fieldCountLabel.topAnchor constraintEqualToAnchor:_nameLabel.bottomAnchor constant:2]
    ]];
}

- (void)configureWithName:(NSString *)name fieldCount:(NSInteger)count {
    _nameLabel.text = name;
    _fieldCountLabel.text = [NSString stringWithFormat:@"%ld fields", (long)count];
}

@end

#pragma mark - Field Cell

@interface ZPProtoFieldCell : UITableViewCell
@property (nonatomic, strong) UILabel *numberLabel;
@property (nonatomic, strong) UILabel *typeLabel;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UIButton *duplicateButton;
@end

@implementation ZPProtoFieldCell

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
    
    _numberLabel = [[UILabel alloc] init];
    _numberLabel.font = [UIFont systemFontOfSize:10 weight:UIFontWeightMedium];
    _numberLabel.textColor = [ZPColors accent];
    _numberLabel.textAlignment = NSTextAlignmentCenter;
    _numberLabel.backgroundColor = [[ZPColors accent] colorWithAlphaComponent:0.15];
    _numberLabel.layer.cornerRadius = 4;
    _numberLabel.layer.masksToBounds = YES;
    _numberLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_numberLabel];
    
    _typeLabel = [[UILabel alloc] init];
    _typeLabel.font = [UIFont systemFontOfSize:11];
    _typeLabel.textColor = [ZPColors textSecondary];
    _typeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_typeLabel];
    
    _nameLabel = [[UILabel alloc] init];
    _nameLabel.font = [UIFont systemFontOfSize:13];
    _nameLabel.textColor = [ZPColors textPrimary];
    _nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_nameLabel];
    
    _duplicateButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_duplicateButton setImage:[UIImage systemImageNamed:@"doc.on.doc"] forState:UIControlStateNormal];
    _duplicateButton.tintColor = [ZPColors textSecondary];
    _duplicateButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_duplicateButton];
    
    [NSLayoutConstraint activateConstraints:@[
        [_numberLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:12],
        [_numberLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:8],
        [_numberLabel.widthAnchor constraintEqualToConstant:24],
        [_numberLabel.heightAnchor constraintEqualToConstant:18],
        
        [_typeLabel.leadingAnchor constraintEqualToAnchor:_numberLabel.trailingAnchor constant:6],
        [_typeLabel.centerYAnchor constraintEqualToAnchor:_numberLabel.centerYAnchor],
        [_typeLabel.widthAnchor constraintEqualToConstant:50],
        
        [_nameLabel.leadingAnchor constraintEqualToAnchor:_typeLabel.trailingAnchor constant:6],
        [_nameLabel.centerYAnchor constraintEqualToAnchor:_numberLabel.centerYAnchor],
        
        [_duplicateButton.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-12],
        [_duplicateButton.centerYAnchor constraintEqualToAnchor:_numberLabel.centerYAnchor],
        [_duplicateButton.widthAnchor constraintEqualToConstant:32],
        [_duplicateButton.heightAnchor constraintEqualToConstant:32]
    ]];
}

- (void)configureWithNumber:(NSInteger)num type:(NSString *)type name:(NSString *)name {
    _numberLabel.text = [@(num) stringValue];
    _typeLabel.text = type;
    _nameLabel.text = name;
}

@end

#pragma mark - ZPProtoView

@interface ZPProtoView () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UIButton *chooseFileButton;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UILabel *fileNameLabel;
@property (nonatomic, strong) UIButton *exportButton;
@property (nonatomic, strong) UILabel *emptyLabel;
@property (nonatomic, strong) NSArray<NSDictionary *> *messages;
@property (nonatomic, strong) NSArray<NSDictionary *> *fields;
@property (nonatomic, assign) BOOL showingFields;
@end

@implementation ZPProtoView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _messages = @[];
        _fields = @[];
        _showingFields = NO;
        [self setupView];
    }
    return self;
}

- (void)setupView {
    // Header with file info
    _headerView = [[UIView alloc] init];
    _headerView.backgroundColor = [ZPColors backgroundTertiary];
    _headerView.layer.cornerRadius = 8;
    _headerView.translatesAutoresizingMaskIntoConstraints = NO;
    _headerView.hidden = YES;
    [self addSubview:_headerView];
    
    UIImageView *fileIcon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"doc.text"]];
    fileIcon.tintColor = [ZPColors accent];
    fileIcon.translatesAutoresizingMaskIntoConstraints = NO;
    [_headerView addSubview:fileIcon];
    
    _fileNameLabel = [[UILabel alloc] init];
    _fileNameLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    _fileNameLabel.textColor = [ZPColors textPrimary];
    _fileNameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [_headerView addSubview:_fileNameLabel];
    
    _exportButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_exportButton setTitle:@"Export JSON" forState:UIControlStateNormal];
    _exportButton.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    _exportButton.tintColor = [ZPColors accent];
    _exportButton.backgroundColor = [[ZPColors accent] colorWithAlphaComponent:0.15];
    _exportButton.layer.cornerRadius = 6;
    _exportButton.contentEdgeInsets = UIEdgeInsetsMake(4, 10, 4, 10);
    _exportButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_exportButton addTarget:self action:@selector(exportJSON) forControlEvents:UIControlEventTouchUpInside];
    [_headerView addSubview:_exportButton];
    
    // Choose file button
    _chooseFileButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_chooseFileButton setTitle:@"  Choose .proto" forState:UIControlStateNormal];
    [_chooseFileButton setImage:[UIImage systemImageNamed:@"folder"] forState:UIControlStateNormal];
    _chooseFileButton.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    _chooseFileButton.tintColor = [ZPColors textPrimary];
    _chooseFileButton.backgroundColor = [ZPColors backgroundTertiary];
    _chooseFileButton.layer.cornerRadius = 12;
    _chooseFileButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_chooseFileButton addTarget:self action:@selector(chooseFile) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_chooseFileButton];
    
    // Table view
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _tableView.backgroundColor = [UIColor clearColor];
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.rowHeight = 52;
    _tableView.translatesAutoresizingMaskIntoConstraints = NO;
    _tableView.hidden = YES;
    [_tableView registerClass:[ZPProtoMessageCell class] forCellReuseIdentifier:@"MessageCell"];
    [_tableView registerClass:[ZPProtoFieldCell class] forCellReuseIdentifier:@"FieldCell"];
    [self addSubview:_tableView];
    
    // Empty state
    _emptyLabel = [[UILabel alloc] init];
    _emptyLabel.text = @"Select a .proto file\nto view messages";
    _emptyLabel.numberOfLines = 0;
    _emptyLabel.textAlignment = NSTextAlignmentCenter;
    _emptyLabel.font = [UIFont systemFontOfSize:14];
    _emptyLabel.textColor = [ZPColors textSecondary];
    _emptyLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_emptyLabel];
    
    [NSLayoutConstraint activateConstraints:@[
        [_headerView.topAnchor constraintEqualToAnchor:self.topAnchor constant:8],
        [_headerView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:12],
        [_headerView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-12],
        [_headerView.heightAnchor constraintEqualToConstant:44],
        
        [fileIcon.leadingAnchor constraintEqualToAnchor:_headerView.leadingAnchor constant:12],
        [fileIcon.centerYAnchor constraintEqualToAnchor:_headerView.centerYAnchor],
        [fileIcon.widthAnchor constraintEqualToConstant:20],
        [fileIcon.heightAnchor constraintEqualToConstant:20],
        
        [_fileNameLabel.leadingAnchor constraintEqualToAnchor:fileIcon.trailingAnchor constant:8],
        [_fileNameLabel.centerYAnchor constraintEqualToAnchor:_headerView.centerYAnchor],
        
        [_exportButton.trailingAnchor constraintEqualToAnchor:_headerView.trailingAnchor constant:-12],
        [_exportButton.centerYAnchor constraintEqualToAnchor:_headerView.centerYAnchor],
        
        [_chooseFileButton.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [_chooseFileButton.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [_chooseFileButton.widthAnchor constraintEqualToConstant:180],
        [_chooseFileButton.heightAnchor constraintEqualToConstant:48],
        
        [_tableView.topAnchor constraintEqualToAnchor:_headerView.bottomAnchor constant:8],
        [_tableView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [_tableView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [_tableView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        
        [_emptyLabel.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [_emptyLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor]
    ]];
}

- (void)chooseFile {
    // In real implementation, this would present UIDocumentPickerViewController
    // For now, show a toast
    [ZPToast show:@"File picker would open here"];
}

- (void)loadProtoFile {
    [self chooseFile];
}

- (void)displayMessages:(NSArray *)messages {
    _messages = messages;
    _fields = @[];
    _showingFields = NO;
    
    _chooseFileButton.hidden = YES;
    _emptyLabel.hidden = YES;
    _headerView.hidden = NO;
    _tableView.hidden = NO;
    
    [_tableView reloadData];
}

- (void)clearMessages {
    _messages = @[];
    _fields = @[];
    _showingFields = NO;
    _chooseFileButton.hidden = NO;
    _emptyLabel.hidden = NO;
    _headerView.hidden = YES;
    _tableView.hidden = YES;
    [_tableView reloadData];
}

- (void)exportJSON {
    [ZPToast show:@"JSON exported"];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _showingFields ? _fields.count : _messages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_showingFields) {
        ZPProtoFieldCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FieldCell" forIndexPath:indexPath];
        if (indexPath.row < _fields.count) {
            NSDictionary *field = _fields[indexPath.row];
            [cell configureWithNumber:[field[@"number"] integerValue]
                                 type:field[@"type"] ?: @"string"
                                 name:field[@"name"] ?: @""];
        }
        return cell;
    } else {
        ZPProtoMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MessageCell" forIndexPath:indexPath];
        if (indexPath.row < _messages.count) {
            NSDictionary *msg = _messages[indexPath.row];
            [cell configureWithName:msg[@"name"] ?: @""
                        fieldCount:[msg[@"fields"] count]];
        }
        return cell;
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (!_showingFields && indexPath.row < _messages.count) {
        NSDictionary *msg = _messages[indexPath.row];
        _fields = msg[@"fields"] ?: @[];
        _showingFields = YES;
        [_tableView reloadData];
        
        // Haptic
        UIImpactFeedbackGenerator *generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
        [generator impactOccurred];
    }
}

@end
