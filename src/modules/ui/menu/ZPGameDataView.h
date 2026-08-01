//
//  ZPGameDataView.h
//  ZoobaProto
//
//  Game Data tab view
//

#import <UIKit/UIKit.h>
#import "ZPBaseView.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZPGameDataView : ZPBaseView

- (void)updatePlayerData:(NSDictionary *)playerData;
- (void)updateMatchHistory:(NSArray *)matches;
- (void)updateInventory:(NSArray *)items;

@end

NS_ASSUME_NONNULL_END
