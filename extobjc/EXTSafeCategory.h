//
//  EXTSafeCategory.h
//  extobjc
//
//  Created by Justin Spahr-Summers on 2010-11-13.
//  Copyright (C) 2012 Justin Spahr-Summers.
//  Released under the MIT license.
//

#import <objc/runtime.h>
#import "metamacros.h"

/**
 * \@safecategory defines the implementation of a safe category named \a CATEGORY on \a CLASS.
 * A safe category will only add methods to \a CLASS if a method by the same
 * name does not already exist (\e not including superclasses). If \c DEBUG is
 * defined and \c NDEBUG is not defined, any method conflicts will abort the
 * application at startup; otherwise, any method conflicts are simply logged,
 * and no overwriting occurs.
 *
 * This macro should be used in implementation files. Normal \@interface blocks
 * can be used in header files to declare safe categories, as long as the name
 * given in parentheses matches \a CATEGORY.
 *
 * To perform tasks when a safe category is loaded, use the \c +load method,
 * which functions identically to \c +load within a regular category. Any \c
 * +load method will be executed exactly once, and is not added to \a CLASS. \a
 * CLASS is guaranteed to have been loaded by the time \c +load executes.
 *
 * @note Depending on the protection level for the instance variables of \a
 * CLASS, a safe category may not be able to access them, even if a regular
 * category could. In practice, accessing instance variables in a category is
 * almost always a bad idea.
 *
 * @warning Protocol categories and safe categories interact in indeterminate
 * ways. If \a CLASS conforms to a protocol which has an EXTProtocolCategory,
 * and both the protocol category and the safe category implement a method by
 * the same name, the safe category may succeed sometimes and fail others.
 *
 * @bug Due to an implementation detail, methods invoked against \c super will
 * actually be invoked against \c self.
 */
#define safecategory(CLASS, CATEGORY) \
    /*
     * create a class used to contain all the methods used in this category – by
     * doing this, we can control and fine-tune the method injection process
     */ \
    interface CLASS ## _ ## CATEGORY ## _MethodContainer : CLASS {} \
    @end \
    \
    @implementation CLASS ## _ ## CATEGORY ## _MethodContainer \
    /*
     * using the "constructor" function attribute, we can ensure that this
     * function is executed only AFTER all the Objective-C runtime setup (i.e.,
     * after all +load methods have been executed)
     */ \
    __attribute__((constructor)) \
    static void ext_ ## CLASS ## _ ## CATEGORY ## _inject (void) { \
        /*
         * use this injection point to load the methods into the target class
         * this is guaranteed to execute after any regular categories have
         * loaded already (though the interaction with EXTProtocolCategory is
         * undefined)
         */ \
        const char *className_ = metamacro_stringify(CLASS ## _ ## CATEGORY ## _MethodContainer); \
        \
        /*
         * get this class, and the class that is the target of injection
         */ \
        Class methodContainer_ = objc_getClass(className_); \
        Class targetClass_ = class_getSuperclass(methodContainer_); \
        \
        /*
         * if this method returns NO, we assume that one or more of the category
         * methods already existed on the target class, and therefore error out
         * (using ext_safeCategoryFailed)
         */ \
        if (!ext_loadSafeCategory(methodContainer_, targetClass_)) {\
            ext_safeCategoryFailed(CLASS, CATEGORY); \
        } \
    }

/*** implementation details follow ***/
BOOL ext_loadSafeCategory (Class methodContainer, Class targetClass);

// if this is a debug build...
#if defined(DEBUG) && !defined(NDEBUG)
    // abort if a safe category fails to load
    #define ext_safeCategoryFailed(CLASS, CATEGORY) \
        do { \
            fprintf(stderr, "ERROR: Failed to fully load safe category %s (%s)\n", metamacro_stringify(CLASS), metamacro_stringify(CATEGORY)); \
            abort(); \
        } while (0)
#else
    // otherwise, just print an error message
    #define ext_safeCategoryFailed(CLASS, CATEGORY) \
        fprintf(stderr, "ERROR: Failed to fully load safe category %s (%s)\n", metamacro_stringify(CLASS), metamacro_stringify(CATEGORY))
#endif

