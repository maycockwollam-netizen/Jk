//
//  ZPNetworkView.h
//  ZoobaProto
//
//  Network tab view
//

#import <UIKit/UIKit.h>
#import "ZPBaseView.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ZPNetworkViewDelegate <NSObject>
@optional
- (void)networkViewDidSelectRequest:(NSDictionary *)request;
- (void)networkViewDidRequestCopy:(NSString *)content;
@end

@interface ZPNetworkView : ZPBaseView

@property (nonatomic, weak, nullable) id<ZPNetworkViewDelegate> delegate;

- (void)addRequest:(NSDictionary *)request;
- (void)clearRequests;

@end

NS_ASSUME_NONNULL_END
