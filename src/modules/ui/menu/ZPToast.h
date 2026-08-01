//
//  ZPToast.h
//  ZoobaProto
//
//  Toast notification view
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZPToast : UIView

+ (void)show:(NSString *)message;
+ (void)show:(NSString *)message inView:(UIView *)view;

@end

NS_ASSUME_NONNULL_END
