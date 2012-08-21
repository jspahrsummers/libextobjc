//
//  EXTSafeCategory.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 2010-11-13.
//  Copyright (C) 2012 Justin Spahr-Summers.
//  Released under the MIT license.
//

#import "EXTSafeCategory.h"
#import "EXTRuntimeExtensions.h"
#import <stdlib.h>

static
void safeCategoryMethodFailed (Class cls, Method method) {
    const char *methodName = sel_getName(method_getName(method));
    const char *className = class_getName(cls);

    BOOL isMeta = class_isMetaClass(cls);
    if (isMeta)
        fprintf(stderr, "ERROR: Could not add class method +%s to %s (a method by the same name already exists)\n", methodName, className);
    else
        fprintf(stderr, "ERROR: Could not add instance method -%s to %s (a method by the same name already exists)\n", methodName, className);
}

/**
 * This loads a safe category into the destination class, making sure not to
 * overwrite any methods that already exist. \a methodContainer is the class
 * containing the methods defined in the safe category. \a targetClass is the
 * destination of the methods.
 *
 * Returns \c YES if all methods loaded without conflicts, or \c NO if
 * loading failed, whether due to a naming conflict or some other error.
 */
BOOL ext_loadSafeCategory (Class methodContainer, Class targetClass) {
    if (!methodContainer || !targetClass)
        return NO;

    return ext_injectMethodsFromClass(
        methodContainer,
        targetClass,
        ext_methodInjectionFailOnAnyExisting | ext_methodInjectionIgnoreLoad,
        &safeCategoryMethodFailed
    );
}

