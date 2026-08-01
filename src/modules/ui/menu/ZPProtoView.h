//
//  ZPProtoView.h
//  ZoobaProto
//
//  Proto tab view
//

#import <UIKit/UIKit.h>
#import "ZPBaseView.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZPProtoView : ZPBaseView

- (void)loadProtoFile;
- (void)displayMessages:(NSArray *)messages;
- (void)clearMessages;

@end

NS_ASSUME_NONNULL_END
