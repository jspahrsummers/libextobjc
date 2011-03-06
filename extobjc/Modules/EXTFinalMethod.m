//
//  EXTFinalMethod.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-03-02.
//  Released into the public domain.
//

#import "EXTFinalMethod.h"
#import "EXTRuntimeExtensions.h"
#import <stdio.h>

BOOL ext_verifyFinalMethod (SEL methodName, Class targetClass) {
	unsigned subclassCount = 0;
	Class *subclasses = ext_copySubclassList(targetClass, &subclassCount);

	BOOL success = YES;
	for (unsigned subclassIndex = 0;subclassIndex < subclassCount;++subclassIndex) {
		Class cls = subclasses[subclassIndex];

		printf("Checking %s for %s\n", class_getName(cls), sel_getName(methodName));
		
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

