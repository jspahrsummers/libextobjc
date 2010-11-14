/*
 *  EXTSafeCategory.m
 *  extobjc
 *
 *  Created by Justin Spahr-Summers on 2010-11-13.
 *  Released into the public domain.
 */

#import "EXTSafeCategory.h"
#import <stdlib.h>

BOOL ext_loadSafeCategory (Class methodContainer) {
	if (!methodContainer)
		return NO;

	Class targetClass = class_getSuperclass(methodContainer);
	if (!targetClass) {
		fprintf(stderr, "ERROR: Could not get target class for %s\n", class_getName(methodContainer));
		return NO;
	}

	BOOL success = YES;
	
	unsigned instanceMethodCount = 0;
	Method *instanceMethods = class_copyMethodList(methodContainer, &instanceMethodCount);

	for (unsigned i = 0;i < instanceMethodCount;++i) {
		Method m = instanceMethods[i];
		SEL name = method_getName(m);
		IMP impl = method_getImplementation(m);
		const char *types = method_getTypeEncoding(m);
		
		if (!class_addMethod(targetClass, name, impl, types)) {
			fprintf(stderr, "ERROR: Could not add instance method -%s to %s (a method by the same name already exists)\n", sel_getName(name), class_getName(targetClass));

			success = NO;
		}
	}

	free(instanceMethods); instanceMethods = NULL;

	unsigned classMethodCount = 0;
	Method *classMethods = class_copyMethodList(object_getClass(methodContainer), &classMethodCount);
	Class targetMetaclass = object_getClass(targetClass);

	for (unsigned i = 0;i < classMethodCount;++i) {
		Method m = classMethods[i];
		SEL name = method_getName(m);
		IMP impl = method_getImplementation(m);
		const char *types = method_getTypeEncoding(m);
		
		if (!class_addMethod(targetMetaclass, name, impl, types)) {
			fprintf(stderr, "ERROR: Could not add class method +%s to %s (a method by the same name already exists)\n", sel_getName(name), class_getName(targetClass));

			success = NO;
		}
	}

	free(classMethods); classMethods = NULL;
	
	return success;
}

