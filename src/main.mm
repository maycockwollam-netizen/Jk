//
//  main.mm
//  ZoobaProto UI
//

#import <UIKit/UIKit.h>
#import <substrate.h>
#import "modules/ui/menu/ZoobaProtoMenu.h"
#import "modules/utils/ZPLogger.h"

#define ZPLog(fmt, args...) NSLog(@"[ZoobaProto] " fmt, ##args)

static NSString * const kVersion = @"2.3.0";

__attribute__((constructor))
static void ZoobaProtoInit() {
    // Start logger first for debugging
    [[ZPLogger shared] startLogging];
    [[ZPLogger shared] log:@"ZoobaProto v2.3.0 initializing..."];
    
    ZPLog(@"ZoobaProto UI v%@ loading...", kVersion);
    [[ZPLogger shared] logFormat:@"Version: %@", kVersion];
    [[ZPLogger shared] logTimestamp:@"Constructor called"];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        @try {
            [[ZPLogger shared] log:@"Attempting to show menu..."];
            [[ZoobaProtoMenu shared] show];
            [[ZPLogger shared] log:@"Menu show() called successfully"];
            ZPLog(@"Menu ready!");
        } @catch (NSException *e) {
            [[ZPLogger shared] logError:[NSString stringWithFormat:@"Menu error: %@", e.reason]];
            ZPLog(@"Error: %@", e.reason);
        }
    });
}
