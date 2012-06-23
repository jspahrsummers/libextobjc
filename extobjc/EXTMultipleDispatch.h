//
//  EXTMultipleDispatch.h
//  extobjc
//
//  Created by Justin Spahr-Summers on 23.06.12.
//  Released into the public domain.
//

#import <Foundation/Foundation.h>
#import "metamacros.h"

// odd variadic indexes are parameter declarations
#define multimethod(...) \
    class NSObject; \
    \
    ext_multimethod_prototype(__VA_ARGS__); \
    \
    + (EXTMultimethodAttributes *)metamacro_concat(ext_copyMultimethodAttributes_, __LINE__) { \
        metamacro_foreach(ext_multimethod_typedef_iter,, __VA_ARGS__) \
        \
        Class parameterClasses[] = { metamacro_foreach(ext_multimethod_paramtypes_iter,, __VA_ARGS__) Nil }; \
        NSUInteger parameterCount = (sizeof(parameterClasses) / sizeof(*parameterClasses)) - 1; \
        \
        return [[EXTMultimethodAttributes alloc] \
            initWithSelector:@selector(metamacro_foreach(ext_multimethod_selector_iter,, __VA_ARGS__)) \
            implementation:(IMP)&metamacro_concat(ext_multimethod_impl_, __LINE__) \
            parameterCount:parameterCount \
            parameterClasses:parameterClasses \
        ]; \
    } \
    \
    ext_multimethod_prototype(__VA_ARGS__)
    /* user code begins here */

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
@property (nonatomic, readonly) IMP implementation;
@property (nonatomic, readonly) NSUInteger parameterCount;
@property (nonatomic, readonly) const Class *parameterClasses;

- (id)initWithSelector:(SEL)selector implementation:(IMP)implementation parameterCount:(NSUInteger)parameterCount parameterClasses:(const Class *)parameterClasses;
@end
