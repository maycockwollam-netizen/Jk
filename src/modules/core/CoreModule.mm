//
//  CoreModule.mm
//  ZoobaProto
//
//  Core module - manages other modules and lifecycle
//

#import "CoreModule.h"
#import "Config.h"

#define ZPLog(fmt, args...) NSLog(@"[ZoobaProto/Core] " fmt, ##args)

@interface CoreModule ()
@property (nonatomic, strong) NSMutableDictionary<NSString *, id> *modules;
@property (nonatomic, strong) NSMutableArray<NSString *> *moduleOrder;
@end

@implementation CoreModule

- (instancetype)init {
    self = [super init];
    if (self) {
        _modules = [NSMutableDictionary dictionary];
        _moduleOrder = [NSMutableArray array];
    }
    return self;
}

#pragma mark - Setup/Teardown

- (void)setup {
    ZPLog(@"Setting up Core module...");
    
    // Register default modules
    [self registerModule:self withName:@"core"];
    
    ZPLog(@"Core module ready. Registered %lu modules", (unsigned long)self.modules.count);
}

- (void)teardown {
    ZPLog(@"Tearing down Core module...");
    
    for (NSString *name in [self.moduleOrder reverseObjectEnumerator]) {
        id module = self.modules[name];
        if ([module respondsToSelector:@selector(teardown)]) {
            [module teardown];
        }
    }
    
    [self.modules removeAllObjects];
    [self.moduleOrder removeAllObjects];
}

#pragma mark - Module Management

- (void)registerModule:(id)module withName:(NSString *)name {
    if (!module || !name) return;
    
    self.modules[name] = module;
    [self.moduleOrder addObject:name];
    
    ZPLog(@"Registered module: %@", name);
}

- (void)unregisterModule:(NSString *)name {
    if (!name) return;
    
    id module = self.modules[name];
    if ([module respondsToSelector:@selector(teardown)]) {
        [module teardown];
    }
    
    [self.modules removeObjectForKey:name];
    [self.moduleOrder removeObject:name];
    
    ZPLog(@"Unregistered module: %@", name);
}

- (id)moduleForName:(NSString *)name {
    return self.modules[name];
}

#pragma mark - Lifecycle

- (void)applicationDidLaunch {
    ZPLog(@"Application launched");
    
    for (NSString *name in self.moduleOrder) {
        id module = self.modules[name];
        if ([module respondsToSelector:@selector(applicationDidLaunch)]) {
            [module applicationDidLaunch];
        }
    }
}

- (void)applicationWillTerminate {
    ZPLog(@"Application will terminate");
    
    for (NSString *name in [self.moduleOrder reverseObjectEnumerator]) {
        id module = self.modules[name];
        if ([module respondsToSelector:@selector(applicationWillTerminate)]) {
            [module applicationWillTerminate];
        }
    }
}

#pragma mark - Utils

- (void)logStatus {
    ZPLog(@"========== CORE STATUS ==========");
    ZPLog(@"Registered modules: %lu", (unsigned long)self.modules.count);
    
    for (NSString *name in self.moduleOrder) {
        ZPLog(@"  - %@", name);
    }
    
    ZPLog(@"================================");
}

@end
