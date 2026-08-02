//
//  ZPLogger.m
//  ZoobaProto
//
//  Continuous file logger for debugging
//

#import "ZPLogger.h"
#import <mach/mach.h>
#import <UIKit/UIKit.h>

@interface ZPLogger ()
@property (nonatomic, strong) NSFileHandle *fileHandle;
@property (nonatomic, strong) NSMutableString *logBuffer;
@property (nonatomic, strong) dispatch_queue_t logQueue;
@property (nonatomic, strong) NSTimer *flushTimer;
@property (nonatomic, strong) NSTimer *heartbeatTimer;
@property (nonatomic, assign) BOOL isLogging;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@end

@implementation ZPLogger

+ (instancetype)shared {
    static ZPLogger *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ZPLogger alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _logBuffer = [NSMutableString string];
        _logQueue = dispatch_queue_create("com.zoobaproto.logger", DISPATCH_QUEUE_SERIAL);
        _isLogging = NO;
        
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
    }
    return self;
}

- (NSString *)logFilePath {
    // Use Documents folder inside the game app sandbox
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths firstObject];
    
    // Create ZoobaProto subdirectory inside game's Documents
    NSString *zpDir = [documentsPath stringByAppendingPathComponent:@"ZoobaProto"];
    [[NSFileManager defaultManager] createDirectoryAtPath:zpDir
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:nil];
    
    NSString *timestamp = [self timestampString];
    NSString *filename = [NSString stringWithFormat:@"zoobaproto_log_%@.txt", timestamp];
    return [zpDir stringByAppendingPathComponent:filename];
}

- (NSString *)timestampString {
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"yyyyMMdd_HHmmss"];
    return [df stringFromDate:[NSDate date]];
}

- (NSString *)formatTimestamp {
    return [_dateFormatter stringFromDate:[NSDate date]];
}

- (void)startLogging {
    if (_isLogging) return;
    
    dispatch_async(_logQueue, ^{
        NSString *logPath = [self logFilePath];
        
        // Create/truncate log file
        [@"" writeToFile:logPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
        self->_fileHandle = [NSFileHandle fileHandleForWritingAtPath:logPath];
        
        if (self->_fileHandle) {
            self->_isLogging = YES;
            
            // Write header
            [self writeLine:@"========================================"];
            [self writeLine:@"ZoobaProto Logger Started"];
            [self writeLine:[NSString stringWithFormat:@"Date: %@", [self formatTimestamp]]];
            [self writeLine:@"========================================"];
            [self writeLine:@""];
            
            // Log system info
            [self logSystemInfo];
            [self writeLine:@""];
            
            // Start heartbeat timer (logs every 5 seconds)
            dispatch_async(dispatch_get_main_queue(), ^{
                self->_heartbeatTimer = [NSTimer scheduledTimerWithTimeInterval:5.0
                                                                        target:self
                                                                      selector:@selector(heartbeat)
                                                                      userInfo:nil
                                                                       repeats:YES];
            });
            
            // Start flush timer (flushes buffer every 1 second)
            dispatch_async(dispatch_get_main_queue(), ^{
                self->_flushTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                                    target:self
                                                                  selector:@selector(flushTimerFired)
                                                                  userInfo:nil
                                                                   repeats:YES];
            });
            
            NSLog(@"[ZoobaProto/ZPLogger] Started logging to: %@", logPath);
            [self writeLine:@"[ZoobaProto] Logger initialized successfully"];
        } else {
            NSLog(@"[ZoobaProto/ZPLogger] Failed to open log file: %@", logPath);
        }
    });
}

- (void)stopLogging {
    if (!_isLogging) return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->_flushTimer invalidate];
        [self->_heartbeatTimer invalidate];
    });
    
    dispatch_sync(_logQueue, ^{
        [self writeLine:@""];
        [self writeLine:@"========================================"];
        [self writeLine:@"ZoobaProto Logger Stopped"];
        [self writeLine:[NSString stringWithFormat:@"Date: %@", [self formatTimestamp]]];
        [self writeLine:@"========================================"];
        [self flush];
        
        [self->_fileHandle closeFile];
        self->_fileHandle = nil;
        self->_isLogging = NO;
    });
}

- (void)heartbeat {
    [self log:@"[HEARTBEAT] ZoobaProto still running"];
    [self logMemoryUsage];
}

- (void)flushTimerFired {
    [self flush];
}

- (void)flush {
    if (!_isLogging || _logBuffer.length == 0) return;
    
    dispatch_async(_logQueue, ^{
        if (self->_fileHandle && self->_logBuffer.length > 0) {
            NSData *data = [self->_logBuffer dataUsingEncoding:NSUTF8StringEncoding];
            [self->_fileHandle writeData:data];
            [self->_logBuffer setString:@""];
        }
    });
}

- (void)writeLine:(NSString *)line {
    if (!_isLogging) return;
    
    NSString *timestampedLine = [NSString stringWithFormat:@"[%@] %@\n", [self formatTimestamp], line];
    [_logBuffer appendString:timestampedLine];
}

- (void)log:(NSString *)message {
    [self writeLine:message];
}

- (void)logFormat:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    [self writeLine:message];
}

- (void)logError:(NSString *)message {
    [self writeLine:[NSString stringWithFormat:@"[ERROR] %@", message]];
}

- (void)logTimestamp:(NSString *)event {
    [self writeLine:[NSString stringWithFormat:@"[TIMESTAMP] %@", event]];
}

- (void)logSystemInfo {
    [self writeLine:@"========== SYSTEM INFO =========="];
    
    // App info
    NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
    [self writeLine:[NSString stringWithFormat:@"App: %@ v%@", 
                     info[@"CFBundleDisplayName"] ?: info[@"CFBundleName"],
                     info[@"CFBundleShortVersionString"]]];
    
    // Device info
    UIDevice *device = [UIDevice currentDevice];
    [self writeLine:[NSString stringWithFormat:@"Device: %@ %@", device.model, device.systemVersion]];
    
    // Screen
    UIScreen *screen = [UIScreen mainScreen];
    CGSize size = screen.bounds.size;
    [self writeLine:[NSString stringWithFormat:@"Screen: %.0fx%.0f (scale: %.1f)", 
                     size.width, size.height, screen.scale]];
    
    // Memory
    [self logMemoryUsage];
    
    [self writeLine:@"================================"];
}

- (void)logMemoryUsage {
    struct task_basic_info info;
    mach_msg_type_number_t size = sizeof(info);
    kern_return_t kerr = task_info(mach_task_self(),
                                   TASK_BASIC_INFO,
                                   (task_info_t)&info,
                                   &size);
    
    if (kerr == KERN_SUCCESS) {
        double mb = (double)info.resident_size / (1024.0 * 1024.0);
        [self writeLine:[NSString stringWithFormat:@"[MEMORY] Used: %.2f MB", mb]];
    }
}

@end
