//
//  ProtoUI.mm
//  ZoobaProto
//
//  Proto File UI Manager - Parse .proto files and save messages
//

#import "ProtoUI.h"
#import "ProtoParser.h"
#import "StorageModule.h"

#define ZPLog(fmt, args...) NSLog(@"[ZoobaProto/ProtoUI] " fmt, ##args)

@interface ProtoUI () <UIDocumentPickerDelegate, UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UIViewController *presentingViewController;
@property (nonatomic, strong) UITableViewController *protoListVC;
@property (nonatomic, strong) NSArray<NSDictionary *> *parsedMessages;
@property (nonatomic, strong) NSString *currentFileName;
@property (nonatomic, strong) UIActivityIndicatorView *loadingIndicator;

@end

@implementation ProtoUI

+ (instancetype)shared {
    static ProtoUI *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ProtoUI alloc] init];
        [instance setup];
    });
    return instance;
}

- (void)setup {
    ZPLog(@"ProtoUI setup");
    _parsedMessages = @[];
}

#pragma mark - File Picker

- (void)showProtoFilePicker {
    ZPLog(@"Showing proto file picker...");
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // Get root view controller
        UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
        while (rootVC.presentedViewController) {
            rootVC = rootVC.presentedViewController;
        }
        
        self.presentingViewController = rootVC;
        
        // Create document picker
        NSArray *types = @[@"public.text", @"public.plain-text"];
        UIDocumentPickerViewController *picker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:types inMode:UIDocumentPickerModeOpen];
        picker.delegate = self;
        picker.allowsMultipleSelection = NO;
        picker.modalPresentationStyle = UIModalPresentationFormSheet;
        
        // Add title
        if (@available(iOS 11.0, *)) {
            picker.accessibilityHint = @"Select a .proto file";
        }
        
        [rootVC presentViewController:picker animated:YES completion:^{
            ZPLog(@"Proto file picker shown");
        }];
    });
}

#pragma mark - UIDocumentPickerDelegate

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    ZPLog(@"Document picked: %lu urls", (unsigned long)urls.count);
    
    if (urls.count == 0) return;
    
    NSURL *url = urls.firstObject;
    NSString *filename = url.lastPathComponent;
    
    ZPLog(@"Selected file: %@", filename);
    
    // Check if it's a proto file
    if (![filename.lowercaseString hasSuffix:@".proto"]) {
        [self showAlert:@"Invalid File" message:@"Please select a .proto file"];
        return;
    }
    
    // Start loading
    [self showLoading];
    
    // Read file content
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error = nil;
        NSString *content = [NSString stringWithContentsOfURL:url usedEncoding:nil error:&error];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self hideLoading];
            
            if (error || !content) {
                ZPLog(@"Error reading file: %@", error.localizedDescription);
                [self showAlert:@"Error" message:@"Could not read the file"];
                return;
            }
            
            // Parse proto content
            self.currentFileName = filename;
            [self parseProtoContent:content fromURL:url];
        });
    });
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
    ZPLog(@"Document picker cancelled");
}

#pragma mark - Proto Parsing

- (void)parseProtoContent:(NSString *)content fromURL:(NSURL *)url {
    ZPLog(@"Parsing proto content from: %@", url.lastPathComponent);
    
    if (!content || content.length == 0) {
        [self showAlert:@"Error" message:@"Empty file content"];
        return;
    }
    
    ZPLog(@"Content length: %lu characters", (unsigned long)content.length);
    
    // Parse messages
    NSMutableArray *messages = [NSMutableArray array];
    
    // Regular expression to find message definitions
    NSError *error = nil;
    NSString *pattern = @"message\\s+(\\w+)\\s*\\{([^}]*)\\}";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                       options:NSRegularExpressionDotMatchesLineSeparator
                                                                         error:&error];
    
    if (error) {
        ZPLog(@"Regex error: %@", error.localizedDescription);
        [self showAlert:@"Parse Error" message:error.localizedDescription];
        return;
    }
    
    NSArray<NSTextCheckingResult *> *matches = [regex matchesInString:content
                                                             options:0
                                                               range:NSMakeRange(0, content.length)];
    
    ZPLog(@"Found %lu message definitions", (unsigned long)matches.count);
    
    for (NSTextCheckingResult *match in matches) {
        NSString *messageName = [content substringWithRange:[match rangeAtIndex:1]];
        NSString *messageBody = [content substringWithRange:[match rangeAtIndex:2]];
        
        // Parse fields in message body
        NSArray *fields = [self parseFieldsFromMessageBody:messageBody];
        
        NSDictionary *messageDict = @{
            @"name": messageName,
            @"fields": fields,
            @"rawBody": messageBody
        };
        
        [messages addObject:messageDict];
        
        ZPLog(@"  Message: %@ (%lu fields)", messageName, (unsigned long)fields.count);
    }
    
    // Also try to find enum definitions
    NSString *enumPattern = @"enum\\s+(\\w+)\\s*\\{([^}]*)\\}";
    NSRegularExpression *enumRegex = [NSRegularExpression regularExpressionWithPattern:enumPattern
                                                                            options:NSRegularExpressionDotMatchesLineSeparator
                                                                              error:nil];
    
    if (!enumRegex) {
        ZPLog(@"Enum regex error (non-fatal)");
    } else {
        NSArray *enumMatches = [enumRegex matchesInString:content
                                                options:0
                                                  range:NSMakeRange(0, content.length)];
        
        for (NSTextCheckingResult *match in enumMatches) {
            NSString *enumName = [content substringWithRange:[match rangeAtIndex:1]];
            NSString *enumBody = [content substringWithRange:[match rangeAtIndex:2]];
            
            // Parse enum values
            NSArray *values = [self parseEnumValuesFromBody:enumBody];
            
            NSDictionary *enumDict = @{
                @"name": enumName,
                @"type": @"enum",
                @"values": values,
                @"rawBody": enumBody
            };
            
            [messages addObject:enumDict];
            
            ZPLog(@"  Enum: %@ (%lu values)", enumName, (unsigned long)values.count);
        }
    }
    
    // Also try to find service definitions
    NSString *servicePattern = @"service\\s+(\\w+)\\s*\\{([^}]*)\\}";
    NSRegularExpression *serviceRegex = [NSRegularExpression regularExpressionWithPattern:servicePattern
                                                                               options:NSRegularExpressionDotMatchesLineSeparator
                                                                                 error:nil];
    
    if (!serviceRegex) {
        ZPLog(@"Service regex error (non-fatal)");
    } else {
        NSArray *serviceMatches = [serviceRegex matchesInString:content
                                                      options:0
                                                        range:NSMakeRange(0, content.length)];
        
        for (NSTextCheckingResult *match in serviceMatches) {
            NSString *serviceName = [content substringWithRange:[match rangeAtIndex:1]];
            NSString *serviceBody = [content substringWithRange:[match rangeAtIndex:2]];
            
            // Parse RPC methods
            NSArray *methods = [self parseRPCMethodsFromBody:serviceBody];
            
            NSDictionary *serviceDict = @{
                @"name": serviceName,
                @"type": @"service",
                @"methods": methods,
                @"rawBody": serviceBody
            };
            
            [messages addObject:serviceDict];
            
            ZPLog(@"  Service: %@ (%lu methods)", serviceName, (unsigned long)methods.count);
        }
    }
    
    // Store parsed messages
    self.parsedMessages = messages;
    
    // Save to storage
    [self saveParsedMessages:messages fromFile:self.currentFileName];
    
    // Show results
    [self showParsedMessages:messages];
}

- (NSArray<NSDictionary *> *)parseFieldsFromMessageBody:(NSString *)body {
    NSMutableArray *fields = [NSMutableArray array];
    
    // Pattern to match field definitions
    // Supports: type name = number [options];
    // Examples:
    //   string name = 1;
    //   int32 level = 3;
    //   repeated Item items = 5;
    //   map<string, int32> counts = 6;
    
    NSError *error = nil;
    NSString *fieldPattern = 
        @"((?:repeated|optional|required)?\\s*)"       // Rule (optional/repeated)
        @"(\\w+(?:<[^>]+>)?)"                          // Type (with generic)
        @"\\s+"                                        // Space
        @"(\\w+)"                                      // Name
        @"\\s*=\\s*"                                  // = 
        @"(\\d+)"                                      // Number
        @"\\s*(?:\\[([^\\]]*)\\])?"                    // [options]
        @"\\s*;?";                                     // Optional semicolon
    
    NSRegularExpression *fieldRegex = [NSRegularExpression regularExpressionWithPattern:fieldPattern
                                                                                options:0
                                                                                  error:&error];
    
    if (error) {
        ZPLog(@"Field regex error: %@", error.localizedDescription);
        return @[];
    }
    
    NSArray<NSTextCheckingResult *> *fieldMatches = [fieldRegex matchesInString:body
                                                                        options:0
                                                                          range:NSMakeRange(0, body.length)];
    
    for (NSTextCheckingResult *match in fieldMatches) {
        NSString *rule = [self trim:[body substringWithRange:[match rangeAtIndex:1]]];
        NSString *type = [self trim:[body substringWithRange:[match rangeAtIndex:2]]];
        NSString *name = [self trim:[body substringWithRange:[match rangeAtIndex:3]]];
        NSString *number = [self trim:[body substringWithRange:[match rangeAtIndex:4]]];
        NSString *options = nil;
        if (match.numberOfRanges > 5 && [match rangeAtIndex:5].location != NSNotFound) {
            options = [self trim:[body substringWithRange:[match rangeAtIndex:5]]];
        }
        
        NSDictionary *field = @{
            @"number": @([number integerValue]),
            @"type": type,
            @"name": name,
            @"rule": rule ?: @"",
            @"options": options ?: @""
        };
        
        [fields addObject:field];
    }
    
    // Also check for map fields
    NSString *mapPattern = @"map<([^,]+),\\s*([^>]+)>\\s+(\\w+)\\s*=\\s*(\\d+)";
    NSRegularExpression *mapRegex = [NSRegularExpression regularExpressionWithPattern:mapPattern
                                                                              options:0
                                                                                error:nil];
    
    if (!mapRegex) {
        ZPLog(@"Map regex error (non-fatal)");
    } else {
        NSArray *mapMatches = [mapRegex matchesInString:body
                                               options:0
                                                 range:NSMakeRange(0, body.length)];
        
        for (NSTextCheckingResult *match in mapMatches) {
            NSString *keyType = [self trim:[body substringWithRange:[match rangeAtIndex:1]]];
            NSString *valueType = [self trim:[body substringWithRange:[match rangeAtIndex:2]]];
            NSString *name = [self trim:[body substringWithRange:[match rangeAtIndex:3]]];
            NSString *number = [self trim:[body substringWithRange:[match rangeAtIndex:4]]];
            
            NSDictionary *field = @{
                @"number": @([number integerValue]),
                @"type": [NSString stringWithFormat:@"map<%@, %@>", keyType, valueType],
                @"name": name,
                @"rule": @"map",
                @"options": @""
            };
            
            [fields addObject:field];
        }
    }
    
    return fields;
}

- (NSArray<NSDictionary *> *)parseEnumValuesFromBody:(NSString *)body {
    NSMutableArray *values = [NSMutableArray array];
    
    // Pattern: name = number;
    NSString *valuePattern = @"(\\w+)\\s*=\\s*(-?\\d+)";
    NSRegularExpression *valueRegex = [NSRegularExpression regularExpressionWithPattern:valuePattern
                                                                                options:0
                                                                                  error:nil];
    
    if (!valueRegex) return @[];
    
    NSArray *matches = [valueRegex matchesInString:body
                                         options:0
                                           range:NSMakeRange(0, body.length)];
    
    for (NSTextCheckingResult *match in matches) {
        NSString *name = [self trim:[body substringWithRange:[match rangeAtIndex:1]]];
        NSString *number = [self trim:[body substringWithRange:[match rangeAtIndex:2]]];
        
        // Skip reserved keywords
        if ([name isEqualToString:@"RESERVED"]) continue;
        
        [values addObject:@{
            @"name": name,
            @"value": @([number integerValue])
        }];
    }
    
    return values;
}

- (NSArray<NSDictionary *> *)parseRPCMethodsFromBody:(NSString *)body {
    NSMutableArray *methods = [NSMutableArray array];
    
    // Pattern: rpc MethodName(Request) returns (Response);
    NSString *methodPattern = @"rpc\\s+(\\w+)\\s*\\(([^)]+)\\)\\s*returns\\s*\\(([^)]+)\\)";
    NSRegularExpression *methodRegex = [NSRegularExpression regularExpressionWithPattern:methodPattern
                                                                                options:0
                                                                                  error:nil];
    
    if (!methodRegex) return @[];
    
    NSArray *matches = [methodRegex matchesInString:body
                                          options:0
                                            range:NSMakeRange(0, body.length)];
    
    for (NSTextCheckingResult *match in matches) {
        NSString *name = [self trim:[body substringWithRange:[match rangeAtIndex:1]]];
        NSString *request = [self trim:[body substringWithRange:[match rangeAtIndex:2]]];
        NSString *response = [self trim:[body substringWithRange:[match rangeAtIndex:3]]];
        
        [methods addObject:@{
            @"name": name,
            @"request": request,
            @"response": response
        }];
    }
    
    return methods;
}

- (NSString *)trim:(NSString *)str {
    return [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

#pragma mark - Storage

- (void)saveParsedMessages:(NSArray *)messages fromFile:(NSString *)filename {
    ZPLog(@"Saving %lu messages from %@", (unsigned long)messages.count, filename);
    
    // Create save data
    NSDictionary *saveData = @{
        @"filename": filename ?: @"unknown",
        @"savedAt": @([[NSDate date] timeIntervalSince1970]),
        @"messageCount": @(messages.count),
        @"messages": messages
    };
    
    // Save to StorageModule
    [[StorageModule shared] saveProtoDefinitions:saveData];
    
    // Also save raw JSON to file
    [self saveToJSONFile:saveData filename:filename];
}

- (void)saveToJSONFile:(NSDictionary *)data filename:(NSString *)filename {
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:NSJSONWritingPrettyPrinted error:&error];
    
    if (error) {
        ZPLog(@"JSON serialization error: %@", error.localizedDescription);
        return;
    }
    
    // Save to documents directory
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = paths.firstObject;
    
    NSString *safeName = [[filename stringByDeletingPathExtension] stringByAppendingString:@"_parsed.json"];
    NSString *filePath = [documentsPath stringByAppendingPathComponent:safeName];
    
    BOOL success = [jsonData writeToFile:filePath atomically:YES];
    
    if (success) {
        ZPLog(@"Saved to: %@", filePath);
    } else {
        ZPLog(@"Failed to save JSON");
    }
}

#pragma mark - Display Results

- (void)showParsedMessages:(NSArray *)messages {
    ZPLog(@"Showing %lu parsed messages", (unsigned long)messages.count);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // Create table view controller
        UITableViewController *vc = [[UITableViewController alloc] initWithStyle:UITableViewStyleGrouped];
        vc.title = [NSString stringWithFormat:@"%@ - %lu messages", self.currentFileName, (unsigned long)messages.count];
        
        UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.tag = 999; // Tag for identification
        [tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"MessageCell"];
        
        vc.tableView = tableView;
        
        // Add export button
        UIBarButtonItem *exportButton = [[UIBarButtonItem alloc] initWithTitle:@"Export JSON"
                                                                          style:UIBarButtonItemStylePlain
                                                                         target:self
                                                                         action:@selector(exportJSON)];
        vc.navigationItem.rightBarButtonItem = exportButton;
        
        // Add clear button
        UIBarButtonItem *clearButton = [[UIBarButtonItem alloc] initWithTitle:@"Clear"
                                                                       style:UIBarButtonItemStylePlain
                                                                      target:self
                                                                      action:@selector(clearParsedData)];
        vc.navigationItem.leftBarButtonItem = clearButton;
        
        // Present
        UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:vc];
        
        UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
        [rootVC presentViewController:navVC animated:YES completion:^{
            ZPLog(@"Proto list shown");
        }];
        
        self.protoListVC = vc;
    });
}

- (void)exportJSON {
    if (self.parsedMessages.count == 0) {
        [self showAlert:@"No Data" message:@"No parsed messages to export"];
        return;
    }
    
    NSDictionary *exportData = @{
        @"filename": self.currentFileName ?: @"unknown",
        @"messageCount": @(self.parsedMessages.count),
        @"messages": self.parsedMessages
    };
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:exportData options:NSJSONWritingPrettyPrinted error:&error];
    
    if (error) {
        [self showAlert:@"Error" message:error.localizedDescription];
        return;
    }
    
    // Create temp file
    NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"zooba_proto_export.json"];
    [jsonData writeToFile:tempPath atomically:YES];
    
    NSURL *fileURL = [NSURL fileURLWithPath:tempPath];
    
    // Share
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[fileURL]
                                                                             applicationActivities:nil];
    
    [self.protoListVC presentViewController:activityVC animated:YES completion:nil];
}

- (void)clearParsedData {
    self.parsedMessages = @[];
    self.currentFileName = nil;
    
    [self.protoListVC dismissViewControllerAnimated:YES completion:^{
        ZPLog(@"Parsed data cleared");
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.parsedMessages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MessageCell" forIndexPath:indexPath];
    
    NSDictionary *message = self.parsedMessages[indexPath.row];
    NSString *name = message[@"name"];
    NSString *type = message[@"type"];
    
    if (type) {
        cell.textLabel.text = [NSString stringWithFormat:@"[%@] %@", type, name];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu fields", 
                                    (unsigned long)[message[@"fields"] ?: message[@"values"] ?: message[@"methods"] count]];
    } else {
        NSArray *fields = message[@"fields"];
        cell.textLabel.text = name;
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu fields", (unsigned long)fields.count];
    }
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *message = self.parsedMessages[indexPath.row];
    [self showMessageDetail:message];
}

- (void)showMessageDetail:(NSDictionary *)message {
    NSString *name = message[@"name"];
    NSArray *fields = message[@"fields"];
    NSString *rawBody = message[@"rawBody"];
    
    NSMutableString *detail = [NSMutableString string];
    [detail appendFormat:@"Message: %@\n", name];
    [detail appendFormat:@"Fields: %lu\n\n", (unsigned long)fields.count];
    
    for (NSDictionary *field in fields) {
        [detail appendFormat:@"  %@ %@ = %@;\n", 
         field[@"type"], field[@"name"], field[@"number"]];
    }
    
    [detail appendFormat:@"\n--- RAW BODY ---\n%@", rawBody];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:name
                                                                   message:detail
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Copy JSON" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [UIPasteboard generalPasteboard].string = [self jsonStringFromMessage:message];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Close" style:UIAlertActionStyleCancel handler:nil]];
    
    [self.protoListVC presentViewController:alert animated:YES completion:nil];
}

- (NSString *)jsonStringFromMessage:(NSDictionary *)message {
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:message options:NSJSONWritingPrettyPrinted error:&error];
    if (error) return @"{}";
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

#pragma mark - Helpers

- (void)showLoading {
    if (!self.loadingIndicator) {
        self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    }
    
    self.loadingIndicator.center = self.presentingViewController.view.center;
    [self.loadingIndicator startAnimating];
    [self.presentingViewController.view addSubview:self.loadingIndicator];
}

- (void)hideLoading {
    [self.loadingIndicator stopAnimating];
    [self.loadingIndicator removeFromSuperview];
}

- (void)showAlert:(NSString *)title message:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                     message:message
                                                              preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        
        UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
        [rootVC presentViewController:alert animated:YES completion:nil];
    });
}

@end
