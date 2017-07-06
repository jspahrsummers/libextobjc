//
//  EXTMixin.h
//  extobjc
//
//  Created by Justin Spahr-Summers on 2010-11-10.
//  Copyright (C) 2012 Justin Spahr-Summers.
//  Released under the MIT license.
//

#import <objc/runtime.h>
#import <stdlib.h>
#import "EXTRuntimeExtensions.h"

/**
 * "Mixes in" the class and instance methods of \a CLASS into pre-existing class
 * \a TARGET. Only the methods of \a CLASS itself, and not any superclasses, are mixed
 * in. Any methods by the same name in \a TARGET are overwritten.
 *
 * This macro should be placed at file scope in an implementation file.
 *
 * @note The mixing in occurs only after all +load methods in the image have been
 * executed.
 *
 * @warning Calls to \c super in mixed-in methods may invoke erratic behavior
 * due to the nature of \c objc_msgSendSuper().
 */
#define EXTMixin(TARGET, CLASS) \
    /*
     * using the "constructor" function attribute, we can ensure that this
     * function is executed only AFTER all the Objective-C runtime setup (i.e.,
     * after all +load methods have been executed)
     */ \
    __attribute__((constructor)) \
    static void ext_ ## TARGET ## _ ## CLASS ## _mixin (void) { \
        /*
         * obtain the class to inject into, and the class from which to copy
         * methods
         */ \
        Class targetClass = objc_getClass(# TARGET); \
        Class sourceClass = objc_getClass(# CLASS); \
        \
        ext_replaceMethodsFromClass(sourceClass, targetClass); \
    }

