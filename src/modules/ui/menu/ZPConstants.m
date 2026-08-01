//
//  ZPConstants.m
//  ZoobaProto
//
//  UI Constants Implementation
//

#import "ZPConstants.h"

// Menu Dimensions
const CGFloat ZPMenuCornerRadius = 22.0;
const CGFloat ZPMenuBorderWidth = 1.0;
const CGFloat ZPBubbleSize = 48.0;
const CGFloat ZPMinimumTouchTarget = 44.0;
const CGFloat ZPMenuHorizontalPadding = 16.0;
const CGFloat ZPHeaderHeight = 44.0;
const CGFloat ZPTabBarHeight = 40.0;

// Animation Durations
const NSTimeInterval ZPAnimationDurationShort = 0.22;
const NSTimeInterval ZPAnimationDurationMedium = 0.28;
const NSTimeInterval ZPAnimationDurationLong = 0.32;

// Notifications
NSString * const ZPMenuStateChangedNotification = @"ZPMenuStateChangedNotification";
NSString * const ZPTabChangedNotification = @"ZPTabChangedNotification";
NSString * const ZPRequestSelectedNotification = @"ZPRequestSelectedNotification";
NSString * const ZPCopyNotification = @"ZPCopyNotification";
