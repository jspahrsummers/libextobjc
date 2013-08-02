//
//  EXTAnnotation.h
//  extobjc
//
//  Created by Justin Spahr-Summers on 27.06.12.
//  Copyright (C) 2012 Justin Spahr-Summers.
//  Released under the MIT license.
//

#import <Foundation/Foundation.h>
#import "metamacros.h"

/**
 * \@annotate applies an annotation to the \@property of \a CLASS that immediately
 * follows the macro. The variadic arguments should be dictionary entries,
 * following the syntax used within dictionary literals.
 *
 * At runtime, the annotation can be retrieved with #ext_getPropertyAnnotation.
 *
 * @code

@interface AnnotatedClass : NSObject

@annotate(AnnotatedClass, @"APIKey": @"object_id")
@property (nonatomic, copy) NSString *objectID;

@annotate(AnnotatedClass, @"APIKey": @"full_name", @"other_info": @5)
@property (nonatomic, copy) NSString *name;

@end

@implementation AnnotatedClass

- (NSString *)APIKeyForProperty:(NSString *)property {
    NSDictionary *annotations = ext_getPropertyAnnotation(self.class, property);
    return annotations[@"APIKey"];
}

@end

 * @endcode
 *
 * @note Due to an implementation detail, each annotation adds at least one byte
 * of space to all instances of \a CLASS. For almost all purposes, the
 * difference in space will be negligible, but it may be detrimental for classes
 * that can have thousands of instances.
 */
#define annotate(CLASS, ...) \
    annotate_(CLASS, metamacro_concat(_, __COUNTER__), __VA_ARGS__)

/**
 * \@annotateClass applies an annotation directly to \a CLASS. The variadic
 * arguments should be dictionary entries, following the syntax used within
 * dictionary literals.
 *
 * At runtime, the annotation can be retrieved with #ext_getClassAnnotation.
 *
 * @code

@annotateClass(AnnotatedClass, @"designatedInitializer": @"initWithName:")
@interface AnnotatedClass : NSObject

- (id)initWithName:(NSString *)name;

@end

 * @endcode
 */
#define annotateClass(CLASS, ...) \
    class CLASS; \
    \
    __attribute__((constructor)) \
    static void ext_annotation_apply_ ## CLASS (void) { \
        Class targetClass = objc_getClass(# CLASS); \
        id annotation = @{ __VA_ARGS__ }; \
        \
        if (!ext_applyAnnotationToClass(targetClass, annotation)) { \
            NSLog(@"*** Failed to apply annotation %@ at %s:%lu", annotation, __FILE__, (unsigned long)__LINE__); \
        } \
    }

/**
 * Returns the annotations applied to \a propertyName on the given class, or
 * \c nil if no such annotations exist.
 */
NSDictionary *ext_getPropertyAnnotation (Class annotatedClass, NSString *propertyName);

/**
 * Returns the annotations applied to the given class (excluding any
 * property-level annotations), or \c nil if no such annotations exist.
 */
NSDictionary *ext_getClassAnnotation (Class annotatedClass);

/*** implementation details follow ***/
#define annotate_(CLASS, ID, ...) \
    /* the name of this property is structured specifically to optimize string
     * comparisons */ \
    property (nonatomic, readonly) unsigned char metamacro_concat(ID, _ext_annotation_marker); \
    @end \
    \
    __attribute__((constructor)) \
    static void metamacro_concat(ext_annotation_apply, ID) (void) { \
        Class targetClass = objc_getClass(# CLASS); \
        const char *markerPropertyName = metamacro_stringify(metamacro_concat(ID, _ext_annotation_marker)); \
        id annotation = @{ __VA_ARGS__ }; \
        \
        if (!ext_applyAnnotationAfterMarkerProperty(targetClass, annotation, markerPropertyName)) { \
            NSLog(@"*** Failed to apply annotation %@ at %s:%lu", annotation, __FILE__, (unsigned long)__LINE__); \
        } \
    } \
    \
    @interface CLASS ()

BOOL ext_applyAnnotationAfterMarkerProperty (Class targetClass, id annotation, const char *markerPropertyName);
BOOL ext_applyAnnotationToClass (Class targetClass, id annotation);
