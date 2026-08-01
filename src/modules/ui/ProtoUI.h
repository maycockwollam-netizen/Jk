//
//  ProtoUI.h
//  ZoobaProto
//
//  Proto File UI Manager
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ProtoUI : NSObject

+ (instancetype)shared;

// Setup
- (void)setup;

// Show proto file picker
- (void)showProtoFilePicker;

// Parse proto file
- (void)parseProtoFileAtURL:(NSURL *)url;

// Parse proto content string
- (void)parseProtoContent:(NSString *)content fromURL:(NSURL *)url;

// Save parsed messages to storage
- (void)saveParsedMessages:(NSArray *)messages fromFile:(NSString *)filename;

// Show parsed messages
- (void)showParsedMessages:(NSArray *)messages;

// Clear all parsed data
- (void)clearParsedData;

@end

NS_ASSUME_NONNULL_END
