//
//  EXTRuntimeExtensions.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-03-05.
//  Released into the public domain.
//

#import "EXTRuntimeExtensions.h"
#import <stdio.h>

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
