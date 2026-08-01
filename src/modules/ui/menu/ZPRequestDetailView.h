//
//  ZPRequestDetailView.h
//  ZoobaProto
//
//  Request detail panel
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ZPRequestDetailDelegate <NSObject>
@optional
- (void)detailDidRequestCopy:(NSString *)content;
- (void)detailDidClose;
@end

@interface ZPRequestDetailView : UIView

@property (nonatomic, weak, nullable) id<ZPRequestDetailDelegate> delegate;

- (void)showWithRequest:(NSDictionary *)request;
- (void)hide;

@end

NS_ASSUME_NONNULL_END
