//
//  Swizzler.h
//  ZoobaProto
//
//  Method Swizzling utility for hooking
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

NS_ASSUME_NONNULL_BEGIN

@interface Swizzler : NSObject

// Class method swizzling
+ (BOOL)swizzleClassMethod:(Class)cls 
           originalSelector:(SEL)original 
                withMethod:(Method)replacement;

+ (BOOL)swizzleClassMethod:(Class)cls 
           originalSelector:(SEL)original 
                withSelector:(SEL)replacement;

// Instance method swizzling
+ (BOOL)swizzleInstanceMethod:(Class)cls 
              originalSelector:(SEL)original 
                   withMethod:(Method)replacement;

+ (BOOL)swizzleInstanceMethod:(Class)cls 
              originalSelector:(SEL)original 
                   withSelector:(SEL)replacement;

// Replace implementation directly
+ (BOOL)replaceMethod:(Class)cls 
             selector:(SEL)selector 
       withBlock:(id)block 
    returnType:(const char *)returnType;

// Hook with custom before/after logic
+ (void)hookMethod:(Class)cls 
          selector:(SEL)selector 
      beforeBlock:(void (^)(id self, NSInvocation *invocation))beforeBlock 
       afterBlock:(void (^)(id self, NSInvocation *invocation, __unsafe_unretained id returnValue))afterBlock;

// Log all methods of a class
+ (void)logAllMethodsOfClass:(Class)cls;

// Find method by name pattern
+ (Method _Nullable)findMethodInClass:(Class)cls 
                       selectorPattern:(NSString *)pattern;

@end

NS_ASSUME_NONNULL_END
