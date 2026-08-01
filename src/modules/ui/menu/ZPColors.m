//
//  ZPColors.m
//  ZoobaProto
//
//  Color palette implementation
//

#import "ZPColors.h"

@implementation ZPColors

#pragma mark - Background
+ (UIColor *)backgroundPrimary {
    return [UIColor colorWithRed:0x16/255.0 green:0x16/255.0 blue:0x1A/255.0 alpha:1.0];
}

+ (UIColor *)backgroundSecondary {
    return [UIColor colorWithRed:0x1C/255.0 green:0x1C/255.0 blue:0x22/255.0 alpha:1.0];
}

+ (UIColor *)backgroundTertiary {
    return [UIColor colorWithRed:0x20/255.0 green:0x20/255.0 blue:0x27/255.0 alpha:1.0];
}

+ (UIColor *)backgroundQuaternary {
    return [UIColor colorWithRed:0x25/255.0 green:0x25/255.0 blue:0x2C/255.0 alpha:1.0];
}

+ (UIColor *)backgroundDark {
    return [UIColor colorWithRed:0x14/255.0 green:0x14/255.0 blue:0x19/255.0 alpha:1.0];
}

#pragma mark - Border
+ (UIColor *)border {
    return [UIColor colorWithRed:0x2C/255.0 green:0x2C/255.0 blue:0x35/255.0 alpha:1.0];
}

#pragma mark - Accent
+ (UIColor *)accent {
    return [UIColor colorWithRed:0x6E/255.0 green:0x7C/255.0 blue:0xE0/255.0 alpha:1.0];
}

#pragma mark - Text
+ (UIColor *)textPrimary {
    return [UIColor colorWithRed:0xF1/255.0 green:0xF1/255.0 blue:0xF5/255.0 alpha:1.0];
}

+ (UIColor *)textSecondary {
    return [UIColor colorWithRed:0x94/255.0 green:0x94/255.0 blue:0xA3/255.0 alpha:1.0];
}

#pragma mark - Method Colors (muted)
+ (UIColor *)methodPOST {
    // muted navy/blue
    return [UIColor colorWithRed:0x3D/255.0 green:0x5A/255.0 blue:0x80/255.0 alpha:1.0];
}

+ (UIColor *)methodGET {
    // muted olive/green
    return [UIColor colorWithRed:0x55/255.0 green:0x6B/255.0 blue:0x4C/255.0 alpha:1.0];
}

+ (UIColor *)methodError {
    // muted dusty pink/red
    return [UIColor colorWithRed:0x8B/255.0 green:0x4D/255.0 blue:0x5C/255.0 alpha:1.0];
}

#pragma mark - Status
+ (UIColor *)statusRecording {
    // muted blue/indigo
    return [UIColor colorWithRed:0x5C/255.0 green:0x6B/255.0 blue:0xA0/255.0 alpha:1.0];
}

@end
