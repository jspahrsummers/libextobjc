//
//  EXTRuntimeExtensions.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-03-05.
//  Released into the public domain.
//

#import "EXTRuntimeExtensions.h"
#import <stdio.h>

typedef enum {
	// the first two bits are used to determine overwriting behavior
	ext_methodInjectionReplace                  = 0x00,
	ext_methodInjectionFailOnExisting           = 0x01,
	ext_methodInjectionFailOnSuperclassExisting = 0x02,
	ext_methodInjectionFailOnAnyExisting        = 0x03,

	// whether to ignore methods named 'load'
	ext_methodInjectionIgnoreLoad = 1U << 2,

	// whether to ignore methods named 'initialize'
	ext_methodInjectionIgnoreInitialize = 1U << 3
} ext_methodInjectionBehavior;

// a mask to get the first two bits of ext_methodInjectionBehavior
static const ext_methodInjectionBehavior ext_methodInjectionOverwriteBehaviorMask = 0x3;

static
id ext_removedMethodCalled (id self, SEL _cmd, ...) {
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

static
unsigned ext_injectMethods (
	Class aClass,
	Method *methods,
	unsigned count,
	ext_methodInjectionBehavior behavior,
	ext_failedMethodCallback failedToAddCallback
) {
	unsigned successes = 0;
	for (unsigned methodIndex = 0;methodIndex < count;++methodIndex) {
		Method method = methods[methodIndex];
		SEL methodName = method_getName(method);

		if (behavior & ext_methodInjectionIgnoreLoad) {
			if (methodName == @selector(load))
				continue;
		}

		if (behavior & ext_methodInjectionIgnoreInitialize) {
			if (methodName == @selector(initialize))
				continue;
		}

		BOOL success = YES;
		IMP impl = method_getImplementation(method);
		const char *type = method_getTypeEncoding(method);

		switch (behavior & ext_methodInjectionOverwriteBehaviorMask) {
		case ext_methodInjectionFailOnExisting:
			success = class_addMethod(aClass, methodName, impl, type);
			break;

		case ext_methodInjectionFailOnAnyExisting:
			if (class_getInstanceMethod(aClass, methodName)) {
				success = NO;
				break;
			}

			// else fall through

		case ext_methodInjectionReplace:
			class_replaceMethod(aClass, methodName, impl, type);
			break;

		case ext_methodInjectionFailOnSuperclassExisting:
			{
				Class superclass = class_getSuperclass(aClass);
				if (superclass && class_getInstanceMethod(superclass, methodName))
					success = NO;
				else
					class_replaceMethod(aClass, methodName, impl, type);
			}

			break;

		default:
			fprintf(stderr, "ERROR: Unrecognized method injection behavior: %i\n", (int)(behavior & ext_methodInjectionOverwriteBehaviorMask));
		}

		if (success)
			++successes;
		else
			failedToAddCallback(aClass, method);
	}

	return successes;
}

unsigned ext_addMethods (Class aClass, Method *methods, unsigned count, BOOL checkSuperclasses, ext_failedMethodCallback failedToAddCallback) {
	ext_methodInjectionBehavior behavior = ext_methodInjectionFailOnExisting;
	if (checkSuperclasses)
		behavior |= ext_methodInjectionFailOnSuperclassExisting;

	return ext_injectMethods(
		aClass,
		methods,
		count,
		behavior,
		failedToAddCallback
	);
}

unsigned ext_addMethodsFromClass (Class srcClass, Class dstClass, BOOL checkSuperclasses, ext_failedMethodCallback failedToAddCallback) {
	unsigned count;
	unsigned successes = 0;

	count = 0;
	Method *instanceMethods = class_copyMethodList(srcClass, &count);

	successes += ext_addMethods(dstClass, instanceMethods, count, checkSuperclasses, failedToAddCallback);
	free(instanceMethods);

	count = 0;
	Method *classMethods = class_copyMethodList(object_getClass(srcClass), &count);

	ext_methodInjectionBehavior behavior = ext_methodInjectionIgnoreLoad | ext_methodInjectionFailOnExisting;
	if (checkSuperclasses)
		behavior |= ext_methodInjectionFailOnSuperclassExisting;

	successes += ext_injectMethods(
		object_getClass(dstClass),
		classMethods,
		count,
		behavior,
		failedToAddCallback
	);

	free(classMethods);
	return successes;
}

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

Method ext_getImmediateInstanceMethod (Class aClass, SEL aSelector) {
	unsigned methodCount = 0;
	Method *methods = class_copyMethodList(aClass, &methodCount);
	Method foundMethod = NULL;

	for (unsigned methodIndex = 0;methodIndex < methodCount;++methodIndex) {
		if (method_getName(methods[methodIndex]) == aSelector) {
			foundMethod = methods[methodIndex];
			break;
		}
	}

	free(methods);
	return foundMethod;
}

void ext_removeMethod (Class aClass, SEL methodName) {
	Method existingMethod = ext_getImmediateInstanceMethod(aClass, methodName);
	if (!existingMethod)
		return;
	
	Method superclassMethod = NULL;
	Class superclass = class_getSuperclass(aClass);
	if (superclass)
		superclassMethod = class_getInstanceMethod(superclass, methodName);
	
	if (superclassMethod)
		method_setImplementation(existingMethod, method_getImplementation(superclassMethod));
	else
		method_setImplementation(existingMethod, (IMP)&ext_removedMethodCalled);
}

void ext_replaceMethods (Class aClass, Method *methods, unsigned count) {
	ext_injectMethods(
		aClass,
		methods,
		count,
		ext_methodInjectionReplace,
		NULL
	);
}

