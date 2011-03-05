//
//  EXTPrivateMethod.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-03-02.
//  Released into the public domain.
//

#import <stdio.h>
#import "EXTPrivateMethod.h"

static
void ext_privateMethodCalled (id self, SEL _cmd, ...) {
	[self doesNotRecognizeSelector:_cmd];
}

BOOL ext_makeMethodPrivate (Class targetClass, SEL methodName) {
	const char *selectorName = sel_getName(methodName);
	const char *className = class_getName(targetClass);

	Class superclass = class_getSuperclass(targetClass);
	if (!superclass) {
		fprintf(stderr, "ERROR: Cannot make method %s private on class %s without a superclass\n", selectorName, className);
		return NO;
	}

	unsigned methodCount = 0;
	Method *methods = class_copyMethodList(targetClass, &methodCount);

	Method foundMethod = NULL;
	for (unsigned methodIndex = 0;methodIndex < methodCount;++methodIndex) {
		Method method = methods[methodIndex];
		if (method_getName(method) == methodName) {
			foundMethod = method;
			break;
		}
	}

	free(methods);
	methods = NULL;

	if (!foundMethod) {
		fprintf(stderr, "ERROR: Method %s not found on class %s\n", selectorName, className);
		return NO;
	}

	// TODO: this should check the superclass for conflicts

	size_t selectorNameLength = strlen(selectorName);
	size_t classNameLength = strlen(className);
	size_t newMethodNameLength = selectorNameLength + classNameLength + 2;

	char *methodNameString = malloc(newMethodNameLength);
	if (!methodNameString) {
		fprintf(stderr, "ERROR: Could not allocate space for method name with %zu characters\n", newMethodNameLength);
		return NO;
	}

	strcpy(methodNameString, selectorName);
	methodNameString[selectorNameLength] = '_';

	strcpy(methodNameString + selectorNameLength + 1, className);
	methodNameString[newMethodNameLength - 1] = '\0';

	SEL newSelector = sel_registerName(methodNameString);
	class_replaceMethod(superclass, newSelector, method_getImplementation(foundMethod), method_getTypeEncoding(foundMethod));

	method_setImplementation(foundMethod, (IMP)&ext_privateMethodCalled);
	return YES;
}

