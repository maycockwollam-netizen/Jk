//
//  ZPSettingsView.h
//  ZoobaProto
//
//  Settings tab view
//

#import <UIKit/UIKit.h>
#import "ZPBaseView.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ZPSettingsViewDelegate <NSObject>
@optional
- (void)settingsDidToggleRecording:(BOOL)enabled;
- (void)settingsDidToggleAutoScroll:(BOOL)enabled;
- (void)settingsDidToggleCompactMode:(BOOL)enabled;
- (void)settingsDidClearLogs;
- (void)settingsDidClearProtoData;
- (void)settingsDidExportSession;
@end

@interface ZPSettingsView : ZPBaseView

@property (nonatomic, weak, nullable) id<ZPSettingsViewDelegate> delegate;

- (void)updateSettings:(NSDictionary *)settings;

@end

NS_ASSUME_NONNULL_END
