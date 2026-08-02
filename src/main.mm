//
//  main.mm
//  ZoobaProto UI
//

#import <UIKit/UIKit.h>
#import <substrate.h>
#import "modules/ui/menu/ZoobaProtoMenu.h"

#define ZPLog(fmt, args...) NSLog(@"[ZoobaProto] " fmt, ##args)

static NSString * const kVersion = @"2.3.0";

__attribute__((constructor))
static void ZoobaProtoInit() {
    ZPLog(@"ZoobaProto UI v%@ loading...", kVersion);

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        @try {
            [[ZoobaProtoMenu shared] show];
            ZPLog(@"Menu ready!");
        } @catch (NSException *e) {
            ZPLog(@"Error: %@", e.reason);
        }
    });
}
