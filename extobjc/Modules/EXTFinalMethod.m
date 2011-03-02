//
//  EXTFinalMethod.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-03-02.
//  Released into the public domain.
//

#include "EXTFinalMethod.h"
#include <stdio.h>

/**
 * Looks through the complete list of classes registered with the runtime and
 * finds all classes which are descendant from \a targetClass. Returns \c
 * *subclassCount classes terminated by a \c NULL. You must \c free() the
 * returned array. If there are no subclasses of \a targetClass, \c NULL is
 * returned.
 *
 * @note \a subclassCount may be \c NULL.
 */
static
Class *ext_copySubclassList (Class targetClass, unsigned *subclassCount) {
	// TODO: this method could use some kinda caching

	// get the number of classes registered with the runtime
	int classCount = objc_getClassList(NULL, 0);
	if (!classCount) {
		fprintf(stderr, "ERROR: No classes registered with the runtime\n");
		if (subclassCount)
			*subclassCount = 0;

		return NULL;
	}

	// allocate space for them
	Class *allClasses = malloc(sizeof(Class) * classCount);
	if (!allClasses) {
		fprintf(stderr, "ERROR: Could allocate memory for all classes\n");
		if (subclassCount)
			*subclassCount = 0;

		return NULL;
	}

	// and then actually pull the list of the class objects
	classCount = objc_getClassList(allClasses, classCount);

	// we're going to reuse allClasses for the return value, so returnIndex will
	// keep track of the indices we replace with new values
	int returnIndex = 0;

	BOOL isMeta = class_isMetaClass(targetClass);

	for (int classIndex = 0;classIndex < classCount;++classIndex) {
		Class cls = allClasses[classIndex];
		Class superclass = class_getSuperclass(cls);
		
		while (superclass != NULL) {
			if (isMeta) {
				if (object_getClass(superclass) == targetClass)
					break;
			} else if (superclass == targetClass)
				break;

			superclass = class_getSuperclass(superclass);
		}

		if (!superclass)
			continue;

		// at this point, 'cls' is definitively a subclass of targetClass
		if (isMeta)
			cls = object_getClass(cls);

		allClasses[returnIndex++] = cls;
	}

	allClasses[returnIndex] = NULL;
	if (subclassCount)
		*subclassCount = (unsigned)returnIndex;
	
	return allClasses;
}

BOOL ext_verifyFinalMethod (SEL methodName, Class targetClass) {
	unsigned subclassCount = 0;
	Class *subclasses = ext_copySubclassList(targetClass, &subclassCount);

	BOOL success = YES;
	for (unsigned subclassIndex = 0;subclassIndex < subclassCount;++subclassIndex) {
		Class cls = subclasses[subclassIndex];
		
		unsigned methodCount = 0;
		Method *methods = class_copyMethodList(cls, &methodCount);

		for (unsigned methodIndex = 0;methodIndex < methodCount;++methodIndex) {
			SEL name = method_getName(methods[methodIndex]);
			if (name == methodName) {
				BOOL isMeta = class_isMetaClass(targetClass);

				success = NO;
				fprintf(stderr, "ERROR: Method %c%s in %s overrides final method by the same name in %s\n", (isMeta ? '+' : '-'), sel_getName(name), class_getName(cls), class_getName(targetClass));
				
				break;
			}
		}

		free(methods);
	}

	free(subclasses);
	return success;
}

