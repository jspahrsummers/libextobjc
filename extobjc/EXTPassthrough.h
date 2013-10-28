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
#import "EXTRuntimeExtensions.h"

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
 
 - (void)renamedMethod;
 - (int)methodWithString:(NSString *)str;
 @end
 
 //
 // OuterClass.m
 //
 @interface InnerClass : NSObject
 
 - (void)voidMethod;
 - (int)methodWithString:(NSString *)str;
 @end
 
 @interface OuterClass ()
 @property (nonatomic, strong) InnerClass *inner;
 @end
 
 @implementation OuterClass
 @passthrough(OuterClass, renamedMethod, self.inner, voidMethod);
 @passthrough(OuterClass, methodWithString:, self.inner);
 
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
 * @note To avoid "incomplete implementation" warnings, passthrough methods may
 * be declared in a category on \a CLASS, as opposed to the main \@interface 
 * block.
 */

/*
 * \@passthrough_property defines \a PROPERTY on \a CLASS to invoke the
 * accessors for a property on another object and return the result.
 * The macro finds the names of the setter and getter automatically. Like
 * \@passthrough, the object to message should be the third argument to the
 * macro.
 *
 * By default, the accessors on the messaged object are assumed to have the
 * same names as the accessors on \a CLASS. \a PROPERTY may pass through to a
 * a property of another name by passing a fourth argument to the macro, which
 * should be the name of the property on the messaged class.
 *
 * @code
 
 //
 // OuterClass.h
 //
 @interface OuterClass : NSObject
 
 @property (nonatomic, getter = hasFlakyCrust, setter = topWithFlakyCrust:) BOOL flakyCrust;
 @property (strong, nonatomic) NSString * fruitType;
 @property (nonatomic) BOOL aLaMode;
 
 @end
 
 @interface OuterClass (PassthroughMethods)
 @property (nonatomic) NSTimeInterval bakingTime;
 @end
 
 //
 // InnerClass.m
 //
 @interface InnerClass : NSObject
 
 @property (nonatomic, getter = hasFlakyCrust, setter = topWithFlakyCrust:) BOOL flakyCrust;
 @property (strong, nonatomic, setter = assignFilling:, getter = whatIsTheFilling) NSString * filling;
 @property (nonatomic, getter = isALaMode) BOOL aLaMode;
 @property (nonatomic) NSTimeInterval bakingTime;
 
 @end
 
 @implementation InnerClass
 @end
 
 @interface OuterClass ()
 @property (nonatomic, strong) InnerClass *inner;
 @end
 
 @implementation OuterClass
 @passthrough_property(OuterClass, flakyCrust, self.inner);
 @passthrough_property(OuterClass, fruitType, self.inner, filling);
 @passthrough_property(OuterClass, aLaMode, self.inner, aLaMode);
 
 - (id)init {
 self = [super init];
 if (!self)
 return nil;
 
 self.inner = [InnerClass new];
 return self;
 }
 
 @end
 
 @implementation OuterClass (PassthroughMethods)
 @passthrough_property(OuterClass, bakingTime, self.inner);
 @end
 
 * @endcode
 *
 * @note If the properties on the two classes have the same base names but
 * different accessors, the property name must be re-specified as the fourth
 * argument in order for the accessor name lookup to take place on the
 * messaged class. (In the example code, this is the \c aLaMode case.)
 *
 * @note The property in the outer class uses a \@dynamic implementation
 * directive to avoid auto-synthesis of accessors pre-empting the forwarding.
 * This means that the \@property declaration and the \@passthrough_property
 * must both be either in the same category or in the main \@interface and 
 * \@implementation blocks, as shown here. This means that passthrough methods 
 * and passthrough properties should not be declared in the same category;
 * a "method definition not found" warning will be issued if the methods are
 * declared but not defined, and if they are defined, no forwarding will take
 * place.
 */

#define passthrough_property(CLASS, PROPERTY, ...) \
dynamic PROPERTY; \
passthrough_(__COUNTER__, CLASS, ext_getterNameForProperty(# CLASS, # PROPERTY), sel_getUid, \
metamacro_if_eq(metamacro_argcount(__VA_ARGS__), 2) \
(metamacro_head(__VA_ARGS__), passthrough_renamed_property_accessor(getter, __VA_ARGS__)) \
(__VA_ARGS__)) \
passthrough_(__COUNTER__, CLASS, ext_setterNameForProperty(# CLASS, # PROPERTY), sel_getUid, \
metamacro_if_eq(metamacro_argcount(__VA_ARGS__), 2) \
(metamacro_head(__VA_ARGS__), passthrough_renamed_property_accessor(setter, __VA_ARGS__)) \
(__VA_ARGS__))

#define passthrough(CLASS, METHOD, ...) \
class CLASS; \
\
passthrough_(__COUNTER__, CLASS, METHOD, @selector, __VA_ARGS__)

/*** implementation details follow ***/ \
#define passthrough_(ID, CLASS, METHOD, SEL_GETTER, ...) \
static id \
(*metamacro_concat(ext_originalMethodSignatureForSelector_, ID)) \
(id, SEL, SEL); \
\
static NSMethodSignature * \
metamacro_concat(ext_methodSignatureForSelector_, ID) \
(CLASS *self, SEL _cmd, SEL selector) { \
if (selector != SEL_GETTER (METHOD)) \
return metamacro_concat(ext_originalMethodSignatureForSelector_, ID)(self, _cmd, selector); \
\
id inner = metamacro_head(__VA_ARGS__); \
SEL innerSelector = passthrough_renamed_method(METHOD, SEL_GETTER, __VA_ARGS__); \
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
if (selector != SEL_GETTER  (METHOD)) \
return metamacro_concat(ext_originalRespondsToSelector_, ID)(self, _cmd, selector); \
\
id inner = metamacro_head(__VA_ARGS__); \
SEL innerSelector = passthrough_renamed_method(METHOD, SEL_GETTER, __VA_ARGS__); \
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
if (invocation.selector != SEL_GETTER (METHOD)) { \
metamacro_concat(ext_originalForwardInvocation_, ID)(self, _cmd, invocation); \
return; \
} \
\
[invocation setTarget:metamacro_head(__VA_ARGS__)]; \
[invocation setSelector:passthrough_renamed_method(METHOD, SEL_GETTER, __VA_ARGS__)]; \
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

#define passthrough_renamed_method(METHOD, SEL_GETTER, ...) \
metamacro_if_eq(metamacro_argcount(__VA_ARGS__), 2) \
( \
/* the renamed method follows the passthrough target */ \
SEL_GETTER (metamacro_at(1, __VA_ARGS__)) \
) \
( \
/* no renaming */ \
SEL_GETTER (METHOD) \
)

#define passthrough_renamed_property_accessor(G_OR_S, ...) \
metamacro_concat(ext_, metamacro_concat(G_OR_S, NameForProperty)) \
(object_getClassName(metamacro_head(__VA_ARGS__)), metamacro_stringify(metamacro_at(1, __VA_ARGS__)))
