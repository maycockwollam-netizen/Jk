//
//  ZPColors.h
//  ZoobaProto
//
//  Color palette for ZoobaProto menu
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZPColors : NSObject

#pragma mark - Background
+ (UIColor *)backgroundPrimary;    // #16161A
+ (UIColor *)backgroundSecondary;  // #1C1C22
+ (UIColor *)backgroundTertiary;   // #202027
+ (UIColor *)backgroundQuaternary; // #25252C
+ (UIColor *)backgroundDark;       // #141419

#pragma mark - Border
+ (UIColor *)border;              // #2C2C35

#pragma mark - Accent
+ (UIColor *)accent;              // #6E7CE0 (DUY NHẤT)

#pragma mark - Text
+ (UIColor *)textPrimary;         // #F1F1F5
+ (UIColor *)textSecondary;        // #9494A3

#pragma mark - Method Colors (muted, not neon)
+ (UIColor *)methodPOST;           // muted navy/blue
+ (UIColor *)methodGET;            // muted olive/green
+ (UIColor *)methodError;          // muted dusty pink/red

#pragma mark - Status
+ (UIColor *)statusRecording;      // muted blue/indigo

@end

NS_ASSUME_NONNULL_END
