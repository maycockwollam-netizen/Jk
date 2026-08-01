//
//  Swizzler.mm
//  ZoobaProto
//
//  Method Swizzling implementation
//

#import "Swizzler.h"
#import <objc/runtime.h>
#import <objc/message.h>

#define ZPLog(fmt, args...) NSLog(@"[ZoobaProto/Swizzler] " fmt, ##args)

static NSMutableDictionary *g_swizzledMethods = nil;

@implementation Swizzler

+ (void)load {
    g_swizzledMethods = [NSMutableDictionary dictionary];
}

#pragma mark - Class Method Swizzling

+ (BOOL)swizzleClassMethod:(Class)cls 
           originalSelector:(SEL)original 
                withMethod:(Method)replacement {
    return [self swizzleClassMethod:cls originalSelector:original withSelector:method_getName(replacement)];
}

+ (BOOL)swizzleClassMethod:(Class)cls 
           originalSelector:(SEL)original 
                withSelector:(SEL)replacement {
    if (!cls || !original || !replacement) {
        ZPLog(@"Error: Invalid parameters for class method swizzle");
        return NO;
    }
    
    Class metaClass = object_getClass(cls);
    if (!metaClass) {
        ZPLog(@"Error: Could not get meta class for %@", NSStringFromClass(cls));
        return NO;
    }
    
    Method originalMethod = class_getClassMethod(metaClass, original);
    Method replacementMethod = class_getClassMethod(metaClass, replacement);
    
    if (!originalMethod) {
        ZPLog(@"Error: Original class method not found: %@", NSStringFromSelector(original));
        return NO;
    }
    
    if (!replacementMethod) {
        ZPLog(@"Error: Replacement class method not found: %@", NSStringFromSelector(replacement));
        return NO;
    }
    
    method_exchangeImplementations(originalMethod, replacementMethod);
    
    NSString *key = [NSString stringWithFormat:@"%@[%@]", NSStringFromClass(cls), NSStringFromSelector(original)];
    g_swizzledMethods[key] = @YES;
    
    ZPLog(@"Swizzled class method: %@", key);
    return YES;
}

#pragma mark - Instance Method Swizzling

+ (BOOL)swizzleInstanceMethod:(Class)cls 
              originalSelector:(SEL)original 
                   withMethod:(Method)replacement {
    return [self swizzleInstanceMethod:cls originalSelector:original withSelector:method_getName(replacement)];
}

+ (BOOL)swizzleInstanceMethod:(Class)cls 
              originalSelector:(SEL)original 
                   withSelector:(SEL)replacement {
    if (!cls || !original || !replacement) {
        ZPLog(@"Error: Invalid parameters for instance method swizzle");
        return NO;
    }
    
    Method originalMethod = class_getInstanceMethod(cls, original);
    Method replacementMethod = class_getInstanceMethod(cls, replacement);
    
    if (!originalMethod) {
        ZPLog(@"Error: Original instance method not found: %@ in %@", 
              NSStringFromSelector(original), NSStringFromClass(cls));
        return NO;
    }
    
    if (!replacementMethod) {
        ZPLog(@"Error: Replacement instance method not found: %@ in %@", 
              NSStringFromSelector(replacement), NSStringFromClass(cls));
        return NO;
    }
    
    // Add the method if it doesn't exist, then exchange
    BOOL added = class_addMethod(cls, 
                                original, 
                                method_getImplementation(replacementMethod), 
                                method_getTypeEncoding(replacementMethod));
    
    if (added) {
        replacementMethod = class_getInstanceMethod(cls, replacement);
        if (!replacementMethod) {
            return NO;
        }
        originalMethod = class_getInstanceMethod(cls, original);
        if (!originalMethod) {
            return NO;
        }
    }
    
    method_exchangeImplementations(originalMethod, replacementMethod);
    
    NSString *key = [NSString stringWithFormat:@"%@[%@]", NSStringFromClass(cls), NSStringFromSelector(original)];
    g_swizzledMethods[key] = @YES;
    
    ZPLog(@"Swizzled instance method: %@", key);
    return YES;
}

#pragma mark - Replace with Block

+ (BOOL)replaceMethod:(Class)cls 
             selector:(SEL)selector 
          withBlock:(id)block 
         returnType:(const char *)returnType {
    if (!cls || !selector || !block) {
        ZPLog(@"Error: Invalid parameters for replaceMethod");
        return NO;
    }
    
    Method method = class_getInstanceMethod(cls, selector);
    if (!method) {
        ZPLog(@"Error: Method not found: %@ in %@", NSStringFromSelector(selector), NSStringFromClass(cls));
        return NO;
    }
    
    IMP newImpl = imp_implementationWithBlock(block);
    
    const char *typeEncoding = returnType ? returnType : method_getTypeEncoding(method);
    
    class_replaceMethod(cls, selector, newImpl, typeEncoding);
    
    ZPLog(@"Replaced method: %@[%@]", NSStringFromClass(cls), NSStringFromSelector(selector));
    return YES;
}

#pragma mark - Hook with Before/After

+ (void)hookMethod:(Class)cls 
          selector:(SEL)selector 
      beforeBlock:(void (^)(id self, NSInvocation *invocation))beforeBlock 
       afterBlock:(void (^)(id self, NSInvocation *invocation, id returnValue))afterBlock {
    
    Method method = class_getInstanceMethod(cls, selector);
    if (!method) {
        ZPLog(@"Error: Cannot hook - method not found: %@ in %@", 
              NSStringFromSelector(selector), NSStringFromClass(cls));
        return;
    }
    
    // Store original implementation
    IMP originalImpl = method_getImplementation(method);
    const char *typeEncoding = method_getTypeEncoding(method);
    
    // Create wrapper block
    __block IMP originalIMP = originalImpl;
    
    id wrapperBlock = ^(id self, NSInvocation *invocation) {
        // Before hook
        if (beforeBlock) {
            beforeBlock(self, invocation);
        }
        
        // Call original
        [invocation setTarget:self];
        [invocation invoke];
        
        // Get return value
        __unsafe_unretained id returnValue = nil;
        char returnType[256];
        method_getReturnType(method, returnType, sizeof(returnType));
        if (returnType[0] != 'v') { // Not void
            __unsafe_unretained id ret = nil;
            [invocation getReturnValue:&ret];
            returnValue = ret;
        }
        
        // After hook
        if (afterBlock) {
            afterBlock(self, invocation, returnValue);
        }
    };
    
    // Replace with wrapper
    IMP wrapperImpl = imp_implementationWithBlock(wrapperBlock);
    class_replaceMethod(cls, selector, wrapperImpl, typeEncoding);
    
    ZPLog(@"Hooked method: %@[%@]", NSStringFromClass(cls), NSStringFromSelector(selector));
}

#pragma mark - Debug Helpers

+ (void)logAllMethodsOfClass:(Class)cls {
    if (!cls) return;
    
    ZPLog(@"=== Methods of %@ ===", NSStringFromClass(cls));
    
    unsigned int methodCount = 0;
    Method *methods = class_copyMethodList(cls, &methodCount);
    
    for (unsigned int i = 0; i < methodCount; i++) {
        Method method = methods[i];
        SEL selector = method_getName(method);
        const char *typeEncoding = method_getTypeEncoding(method);
        
        ZPLog(@"  %@ %s", NSStringFromSelector(selector), typeEncoding);
    }
    
    free(methods);
    
    // Also log superclass
    Class superClass = class_getSuperclass(cls);
    if (superClass) {
        ZPLog(@"  (superclass: %@)", NSStringFromClass(superClass));
    }
}

+ (Method)findMethodInClass:(Class)cls 
              selectorPattern:(NSString *)pattern {
    if (!cls || !pattern) return NULL;
    
    unsigned int methodCount = 0;
    Method *methods = class_copyMethodList(cls, &methodCount);
    
    NSRegularExpression *regex = [NSRegularExpression 
        regularExpressionWithPattern:pattern 
                              options:0 
                                error:nil];
    
    for (unsigned int i = 0; i < methodCount; i++) {
        Method method = methods[i];
        NSString *methodName = NSStringFromSelector(method_getName(method));
        
        NSArray *matches = [regex matchesInString:methodName 
                                         options:0 
                                           range:NSMakeRange(0, methodName.length)];
        
        if (matches.count > 0) {
            free(methods);
            return method;
        }
    }
    
    free(methods);
    return NULL;
}

@end
