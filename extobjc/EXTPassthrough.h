//
//  EXTPassthrough.h
//  extobjc
//
//  Created by Justin Spahr-Summers on 2012-07-03.
//  Copyright (C) 2012 Justin Spahr-Summers.
//  Released under the MIT license.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "metamacros.h"

/**
 * \@passthrough defines \a METHOD on \a CLASS to simply invoke a method on
 * another object and return the result. The object to message should be an
 * expression passed as the third argument to the macro, and may refer to \c
 * self (for instance, to access a property).
 *
 * By default, the message sent to the other object uses the same method name
 * given to the macro. \a METHOD may pass through to a method by a different
 * name by passing a fourth argument to the macro, which should be the name of
 * the message to send.
 *
 * @code

//
// OuterClass.h
//
@interface OuterClass : NSObject
@end

@interface OuterClass (PassthroughMethods)
@property (nonatomic, getter = isEnabled) BOOL enabled;

- (void)renamedMethod;
- (int)methodWithString:(NSString *)str;
@end

//
// OuterClass.m
//
@interface InnerClass : NSObject
@property (nonatomic, getter = isEnabled) BOOL enabled;

- (void)voidMethod;
- (int)methodWithString:(NSString *)str;
@end

@interface OuterClass ()
@property (nonatomic, strong) InnerClass *inner;
@end

@implementation OuterClass
@passthrough(OuterClass, renamedMethod, self.inner, voidMethod);
@passthrough(OuterClass, methodWithString:, self.inner);
@passthrough(OuterClass, isEnabled, self.inner);
@passthrough(OuterClass, setEnabled:, self.inner);

- (id)init {
    self = [super init];
    if (!self)
        return nil;

    self.inner = [InnerClass new];
    return self;
}

@end

@implementation InnerClass
...
@end

 * @endcode
 *
 * @note \a METHOD must denote an instance method.
 *
 * @note To avoid "incomplete implementation" warnings, passthrough methods and
 * properties may be declared in a category on \a CLASS, as opposed to the main
 * \@interface block.
 */
#define passthrough(CLASS, METHOD, ...) \
    class CLASS; \
    \
    passthrough_(__COUNTER__, CLASS, METHOD, __VA_ARGS__)

/*** implementation details follow ***/ \
#define passthrough_(ID, CLASS, METHOD, ...) \
    static id \
    (*metamacro_concat(ext_originalMethodSignatureForSelector_, ID)) \
    (id, SEL, SEL); \
    \
    static NSMethodSignature * \
    metamacro_concat(ext_methodSignatureForSelector_, ID) \
    (CLASS *self, SEL _cmd, SEL selector) { \
        if (selector != @selector(METHOD)) \
            return metamacro_concat(ext_originalMethodSignatureForSelector_, ID)(self, _cmd, selector); \
        \
        id inner = metamacro_head(__VA_ARGS__); \
        SEL innerSelector = passthrough_renamed_method(METHOD, __VA_ARGS__); \
        return [inner methodSignatureForSelector:innerSelector]; \
    } \
    \
    static BOOL \
    (*metamacro_concat(ext_originalRespondsToSelector_, ID)) \
    (id, SEL, SEL); \
    \
    static BOOL \
    metamacro_concat(ext_respondsToSelector_, ID) \
    (CLASS *self, SEL _cmd, SEL selector) { \
        if (selector != @selector(METHOD)) \
            return metamacro_concat(ext_originalRespondsToSelector_, ID)(self, _cmd, selector); \
        \
        id inner = metamacro_head(__VA_ARGS__); \
        SEL innerSelector = passthrough_renamed_method(METHOD, __VA_ARGS__); \
        return [inner respondsToSelector:innerSelector]; \
    } \
    \
    static void \
    (*metamacro_concat(ext_originalForwardInvocation_, ID)) \
    (id, SEL, id); \
    \
    static void \
    metamacro_concat(ext_forwardInvocation_, ID) \
    (CLASS *self, SEL _cmd, NSInvocation *invocation) { \
        if (invocation.selector != @selector(METHOD)) { \
            metamacro_concat(ext_originalForwardInvocation_, ID)(self, _cmd, invocation); \
            return; \
        } \
        \
        [invocation setTarget:metamacro_head(__VA_ARGS__)]; \
        [invocation setSelector:passthrough_renamed_method(METHOD, __VA_ARGS__)]; \
        [invocation invoke]; \
    } \
    \
    __attribute__((constructor)) \
    static void metamacro_concat(ext_passthrough_injection_, ID) (void) { \
        Class outerClass = objc_getClass(# CLASS); \
        \
        Method methodSignatureForSelector = class_getInstanceMethod(outerClass, @selector(methodSignatureForSelector:)); \
        Method respondsToSelector = class_getInstanceMethod(outerClass, @selector(respondsToSelector:)); \
        Method forwardInvocation = class_getInstanceMethod(outerClass, @selector(forwardInvocation:)); \
        \
        metamacro_concat(ext_originalMethodSignatureForSelector_, ID) = \
            (id (*)(id, SEL, SEL))method_getImplementation(methodSignatureForSelector); \
        \
        metamacro_concat(ext_originalRespondsToSelector_, ID) = \
            (BOOL (*)(id, SEL, SEL))method_getImplementation(respondsToSelector); \
        \
        metamacro_concat(ext_originalForwardInvocation_, ID) = \
            (void (*)(id, SEL, id))method_getImplementation(forwardInvocation); \
        \
        class_replaceMethod( \
            outerClass, \
            @selector(methodSignatureForSelector:), \
            (IMP)&metamacro_concat(ext_methodSignatureForSelector_, ID), \
            method_getTypeEncoding(methodSignatureForSelector) \
        ); \
        \
        class_replaceMethod( \
            outerClass, \
            @selector(respondsToSelector:), \
            (IMP)&metamacro_concat(ext_respondsToSelector_, ID), \
            method_getTypeEncoding(respondsToSelector) \
        ); \
        \
        class_replaceMethod( \
            outerClass, \
            @selector(forwardInvocation:), \
            (IMP)&metamacro_concat(ext_forwardInvocation_, ID), \
            method_getTypeEncoding(forwardInvocation) \
        ); \
    }

#define passthrough_renamed_method(METHOD, ...) \
    @selector(metamacro_if_eq(1, metamacro_argcount(__VA_ARGS__)) \
        ( \
            /* no renaming */ \
            METHOD \
        ) \
        ( \
            /* the renamed method follows the passthrough target */ \
            metamacro_at(1, __VA_ARGS__) \
        ) \
    )
