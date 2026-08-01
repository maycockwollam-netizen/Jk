//
//  UtilsModule.mm
//  ZoobaProto
//
//  Utility functions and helpers
//

#import "UtilsModule.h"
#import "Config.h"
#import <UIKit/UIKit.h>

#define ZPLog(fmt, args...) NSLog(@"[ZoobaProto/Utils] " fmt, ##args)

@implementation UtilsModule

- (void)setup {
    ZPLog(@"Setting up Utils module...");
    ZPLog(@"Utils module ready");
}

- (void)teardown {
    ZPLog(@"Tearing down Utils module...");
}

#pragma mark - Notifications

- (void)notifyTokenFound:(NSString *)token {
    if (![Config shared].notifyOnToken) return;
    
    ZPLog(@"🔔 NOTIFICATION: Token found!");
    
    // Post notification
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ZoobaProtoTokenFound"
                                                        object:nil
                                                      userInfo:@{@"token": token}];
    
    // Local notification (if permitted)
    [self showLocalNotification:@"ZoobaProto" body:@"Bearer Token detected!"];
}

- (void)notifyEvent:(NSString *)eventName data:(NSDictionary *)data {
    ZPLog(@"📢 Event: %@", eventName);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ZoobaProtoEvent"
                                                        object:nil
                                                      userInfo:@{
                                                          @"event": eventName,
                                                          @"data": data ?: @{}
                                                      }];
}

- (void)showLocalNotification:(NSString *)title body:(NSString *)body {
    // Note: Local notifications require permission
    // This is a simplified implementation
    
    ZPLog(@"📱 Local Notification - Title: %@, Body: %@", title, body);
}

#pragma mark - Logging

- (void)logHexDump:(NSData *)data label:(NSString *)label {
    if (!data || data.length == 0) {
        ZPLog(@"HexDump: No data");
        return;
    }
    
    NSMutableString *output = [NSMutableString string];
    [output appendFormat:@"HexDump%@ (%lu bytes):\n", label ? [NSString stringWithFormat:@" - %@", label] : @"", (unsigned long)data.length];
    
    const unsigned char *bytes = (const unsigned char *)data.bytes;
    NSUInteger length = MIN(data.length, 256); // Limit to 256 bytes
    
    for (NSUInteger i = 0; i < length; i += 16) {
        [output appendFormat:@"%08lx: ", (unsigned long)i];
        
        // Hex
        for (NSUInteger j = 0; j < 16; j++) {
            if (i + j < length) {
                [output appendFormat:@"%02x ", bytes[i + j]];
            } else {
                [output appendString:@"   "];
            }
            if (j == 7) [output appendString:@" "];
        }
        
        [output appendString:@"| "];
        
        // ASCII
        for (NSUInteger j = 0; j < 16 && i + j < length; j++) {
            unsigned char c = bytes[i + j];
            [output appendFormat:@"%c", (c >= 32 && c < 127) ? c : '.'];
        }
        
        [output appendString:@"\n"];
    }
    
    if (data.length > 256) {
        [output appendFormat:@"... (%lu more bytes)\n", (unsigned long)(data.length - 256)];
    }
    
    ZPLog(@"%@", output);
}

- (void)logSeparator {
    ZPLog(@"===============================================");
}

#pragma mark - File Operations

- (NSString *)documentsPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return paths.firstObject;
}

- (NSString *)tempPath {
    return NSTemporaryDirectory();
}

- (BOOL)writeData:(NSData *)data toFile:(NSString *)filename {
    NSString *path = [[self documentsPath] stringByAppendingPathComponent:filename];
    NSError *error;
    BOOL success = [data writeToFile:path options:NSDataWritingAtomic error:&error];
    
    if (success) {
        ZPLog(@"Wrote data to: %@", path);
    } else {
        ZPLog(@"Failed to write data: %@", error.localizedDescription);
    }
    
    return success;
}

- (NSData *)readDataFromFile:(NSString *)filename {
    NSString *path = [[self documentsPath] stringByAppendingPathComponent:filename];
    return [NSData dataWithContentsOfFile:path];
}

#pragma mark - String Utilities

- (BOOL)isValidJWT:(NSString *)string {
    if (!string || string.length < 10) return NO;
    
    // JWT format: xxx.yyy.zzz (base64url encoded)
    NSArray *parts = [string componentsSeparatedByString:@"."];
    if (parts.count != 3) return NO;
    
    // First part should start with "eyJ" (base64url of '{"')
    NSString *firstPart = parts.firstObject;
    if (![firstPart hasPrefix:@"eyJ"] && ![firstPart hasPrefix:@"eyI"]) return NO;
    
    return YES;
}

- (NSString *)extractBearerToken:(NSString *)string {
    if (!string) return nil;
    
    NSString *trimmed = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if ([trimmed.lowercaseString hasPrefix:@"bearer "]) {
        return [trimmed substringFromIndex:7];
    }
    
    if ([self isValidJWT:trimmed]) {
        return trimmed;
    }
    
    return nil;
}

- (NSString *)hexDumpString:(NSData *)data {
    if (!data) return nil;
    
    NSMutableString *hex = [NSMutableString string];
    const unsigned char *bytes = (const unsigned char *)data.bytes;
    
    for (NSUInteger i = 0; i < MIN(data.length, 100); i++) {
        [hex appendFormat:@"%02X", bytes[i]];
    }
    
    if (data.length > 100) {
        [hex appendString:@"..."];
    }
    
    return hex;
}

@end
