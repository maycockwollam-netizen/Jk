//
//  ZPConstants.h
//  ZoobaProto
//
//  UI Constants
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// Menu States
typedef NS_ENUM(NSInteger, ZPMenuState) {
    ZPMenuStateCollapsed = 0,
    ZPMenuStateExpanded = 1
};

// Tab Types
typedef NS_ENUM(NSInteger, ZPTabType) {
    ZPTabTypeNetwork = 0,
    ZPTabTypeProto = 1,
    ZPTabTypeGameData = 2,
    ZPTabTypeSettings = 3
};

// HTTP Methods
typedef NS_ENUM(NSInteger, ZPHTTPMethod) {
    ZPHTTPMethodGET = 0,
    ZPHTTPMethodPOST = 1,
    ZPHTTPMethodPUT = 2,
    ZPHTTPMethodDELETE = 3
};

// Menu Dimensions
extern const CGFloat ZPMenuCornerRadius;
extern const CGFloat ZPMenuBorderWidth;
extern const CGFloat ZPBubbleSize;
extern const CGFloat ZPMinimumTouchTarget;
extern const CGFloat ZPMenuHorizontalPadding;
extern const CGFloat ZPHeaderHeight;
extern const CGFloat ZPTabBarHeight;

// Animation Durations
extern const NSTimeInterval ZPAnimationDurationShort;
extern const NSTimeInterval ZPAnimationDurationMedium;
extern const NSTimeInterval ZPAnimationDurationLong;

// Notifications
extern NSString * const ZPMenuStateChangedNotification;
extern NSString * const ZPTabChangedNotification;
extern NSString * const ZPRequestSelectedNotification;
extern NSString * const ZPCopyNotification;

NS_ASSUME_NONNULL_END
