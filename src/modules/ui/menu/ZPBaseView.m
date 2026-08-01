//
//  ZPBaseView.m
//  ZoobaProto
//
//  Base view implementation
//

#import "ZPBaseView.h"

@implementation ZPBaseView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        [self setupView];
    }
    return self;
}

- (void)setupView {
    // Override in subclasses
}

- (void)refreshData {
    // Override in subclasses
}

@end
