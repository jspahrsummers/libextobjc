//
//  EXTMultimethod.h
//  extobjc
//
//  Created by Justin Spahr-Summers on 23.06.12.
//  Copyright (C) 2012 Justin Spahr-Summers.
//  Released under the MIT license.
//

#import <Foundation/Foundation.h>
#import "metamacros.h"

/**
 * \@multimethod defines an implementation of a multimethod. When the
 * implementing object receives a message for the multimethod's selector, the
 * implementation that best matches the arguments given is the one that will be
 * invoked.
 *
 * Once defined, multimethods must be loaded into the implementing class using
 * #load_multimethods.
 *
 * @code
 
@multimethod(-describe:, id obj) {
    return [obj description];
}
 
@multimethod(-describe:, NSString *str) {
    return str;
}

@multimethod(+combine:, NSNumber *obj, with:, NSNumber *obj2) {
    return @(obj.doubleValue + obj2.doubleValue);
}

@multimethod(+combine:, NSString *str, with:, NSString *str2) {
    return [str stringByAppendingString:str2];
}

 * @endcode
 *
 * The best multimethod match is determined roughly according to the following
 * rules:
 *
 *  - Class arguments only match parameters of type \c Class.
 *  - \c nil arguments prefer the most general definition; for example, they'll
 *  match \c id before \c NSString. However, other arguments take higher
 *  priority.
 *  - Otherwise, if an argument would match two definitions, the more specific
 *  definition is preferred; for example, \c @5 will match \c NSNumber before \c
 *  NSValue.
 *  - If a match is still ambiguous, which implementation is chosen is
 *  undefined.
 *
 * Multimethod implementations in any superclasses are considered at the same
 * time as those in the receiving class. If the best match is found in both the
 * descendant and an ancestor, the descendant's implementation takes priority.
 *
 * @note Multimethods may only accept object arguments (between one and ten,
 * inclusive), and must return an object.
 *
 * @bug Due to an implementation detail, methods cannot be invoked against \c
 * super in the implementation of a multimethod, and property dot-syntax will
 * not work against \c self.
 * 
 * @todo With support from libffi, multimethods could be refactored to accept
 * primitive arguments and return any type, instead of being limited to objects.
 */
#define multimethod(...) \
    class NSObject; \
    \
    ext_multimethod_prototype(__VA_ARGS__); \
    \
    + (EXTMultimethodAttributes *)metamacro_concat(ext_copyMultimethodAttributes_, __LINE__) { \
        /* odd variadic indexes are parameter declarations */ \
        metamacro_foreach(ext_multimethod_typedef_iter,, __VA_ARGS__) \
        \
        Class parameterClasses[] = { metamacro_foreach(ext_multimethod_paramtypes_iter,, __VA_ARGS__) Nil }; \
        NSUInteger parameterCount = (sizeof(parameterClasses) / sizeof(*parameterClasses)) - 1; \
        \
        return [[EXTMultimethodAttributes alloc] \
            initWithName:metamacro_stringify(metamacro_foreach(ext_multimethod_selector_iter,, __VA_ARGS__)) \
            implementation:(IMP)&metamacro_concat(ext_multimethod_impl_, __LINE__) \
            parameterCount:parameterCount \
            parameterClasses:parameterClasses \
        ]; \
    } \
    \
    ext_multimethod_prototype(__VA_ARGS__)
    /* user code begins here */

/**
 * \@load_multimethods will inject all multimethod implementations defined
 * within CLASS.
 *
 * This must be used for multimethods to become active.
 */
#define load_multimethods(CLASS) \
    class CLASS; \
    \
    __attribute__((constructor)) \
    static void metamacro_concat(ext_loadClassMultimethods_, __LINE__)(void) { \
        ext_loadMultimethods([CLASS class]); \
    }

/*** implementation details follow ***/
#define ext_multimethod_typedef_iter(INDEX, ARG) \
    metamacro_if_eq(0, metamacro_is_even(INDEX)) \
        ( \
            typedef ARG, EXT_MULTIMETHOD_CURRENT_TYPEDEF_T(INDEX); \
        ) \
        (/* part of the selector, do nothing */)

#define ext_multimethod_selector_iter(INDEX, ARG) \
    metamacro_if_eq(0, metamacro_is_even(INDEX)) \
        (/* parameter declaration, do nothing */) \
        (ARG) 

#define ext_multimethod_prototype(...) \
    static id \
    metamacro_concat(ext_multimethod_impl_, __LINE__) \
    (id self, SEL _cmd metamacro_foreach(ext_multimethod_prototype_iter,, __VA_ARGS__))

#define ext_multimethod_comma ,

#define ext_multimethod_prototype_iter(INDEX, ARG) \
    metamacro_if_eq(0, metamacro_is_even(INDEX)) \
        (ext_multimethod_comma ARG) \
        (/* part of the selector, do nothing */)

#define ext_multimethod_paramtypes_iter(INDEX, ARG) \
    metamacro_if_eq(0, metamacro_is_even(INDEX)) \
        (ext_multimethod_parameterClassFromEncoding(@encode(EXT_MULTIMETHOD_CURRENT_TYPEDEF_T(INDEX))), ) \
        (/* part of the selector, do nothing */)

#define EXT_MULTIMETHOD_CURRENT_TYPEDEF_T(INDEX) \
    metamacro_concat(metamacro_concat(ext_multimethod_, __LINE__), metamacro_concat(_arg_, INDEX))

// used to represent parameters of type Class, so we can differentiate them
// against parameters of type id
@interface EXTMultimethod_Class_Parameter_Placeholder : NSObject
@end

Class ext_multimethod_parameterClassFromEncoding (const char *encoding);
BOOL ext_loadMultimethods (Class targetClass);

@interface EXTMultimethodAttributes : NSObject <NSCopying>
@property (nonatomic, readonly) SEL selector;
@property (nonatomic, getter = isClassMethod, readonly) BOOL classMethod;
@property (nonatomic, readonly) IMP implementation;
@property (nonatomic, readonly) NSUInteger parameterCount;
@property (nonatomic, readonly) const Class *parameterClasses;

- (id)initWithName:(const char *)name implementation:(IMP)implementation parameterCount:(NSUInteger)parameterCount parameterClasses:(const Class *)parameterClasses;
@end
