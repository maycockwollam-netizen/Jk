//
//  ZoobaProtoMenu.h
//  ZoobaProto
//
//  Main menu container with expanded/collapsed states
//

#import <UIKit/UIKit.h>
#import "ZPConstants.h"

NS_ASSUME_NONNULL_BEGIN

@class ZoobaProtoMenu;

@protocol ZoobaProtoMenuDelegate <NSObject>
@optional
- (void)menuDidChangeState:(ZPMenuState)state;
- (void)menuDidSelectTab:(ZPTabType)tabType;
- (void)menuDidRequestDismiss;
@end

@interface ZoobaProtoMenu : UIView

+ (instancetype)shared;

@property (nonatomic, weak, nullable) id<ZoobaProtoMenuDelegate> delegate;
@property (nonatomic, assign, readonly) ZPMenuState menuState;
@property (nonatomic, assign, readonly) ZPTabType currentTab;

// Menu Control
- (void)show;
- (void)hide;
- (void)toggle;

// Tab Selection
- (void)selectTab:(ZPTabType)tabType;

// Recording State
@property (nonatomic, assign, getter=isRecording) BOOL recording;
- (void)setRecording:(BOOL)recording animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
