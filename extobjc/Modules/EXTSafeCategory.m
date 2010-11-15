/*
 *  EXTSafeCategory.m
 *  extobjc
 *
 *  Created by Justin Spahr-Summers on 2010-11-13.
 *  Released into the public domain.
 */

#import "EXTSafeCategory.h"
#import <stdlib.h>

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

	// default to success until an error occurs
	BOOL success = YES;
	
	// get the instance methods in the category
	unsigned instanceMethodCount = 0;
	Method *instanceMethods = class_copyMethodList(methodContainer, &instanceMethodCount);

	// loop through them and inject them one-by-one
	for (unsigned i = 0;i < instanceMethodCount;++i) {
		Method m = instanceMethods[i];
		SEL name = method_getName(m);
		IMP impl = method_getImplementation(m);
		const char *types = method_getTypeEncoding(m);
		
		// attempt to add the method non-destructively to the target class
		if (!class_addMethod(targetClass, name, impl, types)) {
			// the method already existed, so log an error
			fprintf(stderr, "ERROR: Could not add instance method -%s to %s (a method by the same name already exists)\n", sel_getName(name), class_getName(targetClass));

			// indicate that this injection will not be a success, but continue
			// with the rest of the methods
			success = NO;
		}
	}

	// free the copied instance method list
	free(instanceMethods); instanceMethods = NULL;

	// to add class methods, we need the class of the class, also known as its
	// metaclass
	Class targetMetaclass = object_getClass(targetClass);

	// get the class methods in the category
	unsigned classMethodCount = 0;
	Method *classMethods = class_copyMethodList(object_getClass(methodContainer), &classMethodCount);

	// loop through and inject them one-by-one
	for (unsigned i = 0;i < classMethodCount;++i) {
		Method m = classMethods[i];
		SEL name = method_getName(m);
		IMP impl = method_getImplementation(m);
		const char *types = method_getTypeEncoding(m);
		
		// attempt to add the method non-destructively to the metaclass
		// (meaning as a class method on the class)
		if (!class_addMethod(targetMetaclass, name, impl, types)) {
			// the method already existed, so log an error
			fprintf(stderr, "ERROR: Could not add class method +%s to %s (a method by the same name already exists)\n", sel_getName(name), class_getName(targetClass));

			// indicate that this injection will not be a success, but continue
			// with the rest of the methods
			success = NO;
		}
	}

	// free the copied class method list
	free(classMethods); classMethods = NULL;
	
	return success;
}

