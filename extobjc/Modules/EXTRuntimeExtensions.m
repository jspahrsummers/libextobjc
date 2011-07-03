//
//  EXTRuntimeExtensions.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-03-05.
//  Released into the public domain.
//

#import "EXTRuntimeExtensions.h"
#import <objc/message.h>
#import <ctype.h>
#import <stdio.h>
#import <stdlib.h>
#import <string.h>

typedef NSMethodSignature *(*methodSignatureForSelectorIMP)(id, SEL, SEL);
typedef size_t (*indexedIvarSizeIMP)(id, SEL);

static void * const kIndexedIvarSizeKey = "IndexedIvarSize";

static
id ext_allocWithZonePlusIndexedIvars (id self, SEL _cmd, NSZone *zone) {
	NSUInteger indexedIvarSize = 0;

	Class cls = self;
	while (cls) {
		NSNumber *num = objc_getAssociatedObject(cls, kIndexedIvarSizeKey);
		NSUInteger numValue = [num unsignedIntegerValue];
		
		if (numValue) {
			// keep each class' ivars aligned at 32 bytes for safety
			if ((indexedIvarSize & 0x1F) != 0) {
				// round up to a multiple of 32
				indexedIvarSize = (indexedIvarSize & 0x1F) + 0x20;
			}

			indexedIvarSize += numValue;
		}

		cls = class_getSuperclass(cls);
	}

	return NSAllocateObject(
		self,
		indexedIvarSize,
		zone
	);
}

unsigned ext_injectMethods (
	Class aClass,
	Method *methods,
	unsigned count,
	ext_methodInjectionBehavior behavior,
	ext_failedMethodCallback failedToAddCallback
) {
	unsigned successes = 0;

	/*
	 * set up an autorelease pool in case any Cocoa classes invoke +initialize
	 * during this process
	 */
	@autoreleasepool {
		BOOL isMeta = class_isMetaClass(aClass);

		if (!isMeta) {
			// clear any +load and +initialize ignore flags
			behavior &= ~(ext_methodInjectionIgnoreLoad | ext_methodInjectionIgnoreInitialize);
		}

		for (unsigned methodIndex = 0;methodIndex < count;++methodIndex) {
			Method method = methods[methodIndex];
			SEL methodName = method_getName(method);

			if (behavior & ext_methodInjectionIgnoreLoad) {
				if (methodName == @selector(load)) {
					++successes;
					continue;
				}
			}

			if (behavior & ext_methodInjectionIgnoreInitialize) {
				if (methodName == @selector(initialize)) {
					++successes;
					continue;
				}
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
	}

	return successes;
}

BOOL ext_injectMethodsFromClass (
	Class srcClass,
	Class dstClass,
	ext_methodInjectionBehavior behavior,
	ext_failedMethodCallback failedToAddCallback)
{
	unsigned count, addedCount;
	BOOL success = YES;

	count = 0;
	Method *instanceMethods = class_copyMethodList(srcClass, &count);

	addedCount = ext_injectMethods(
		dstClass,
		instanceMethods,
		count,
		behavior,
		failedToAddCallback
	);

	free(instanceMethods);
	if (addedCount < count)
		success = NO;

	count = 0;
	Method *classMethods = class_copyMethodList(object_getClass(srcClass), &count);

	// ignore +load
	behavior |= ext_methodInjectionIgnoreLoad;
	addedCount = ext_injectMethods(
		object_getClass(dstClass),
		classMethods,
		count,
		behavior,
		failedToAddCallback
	);

	free(classMethods);
	if (addedCount < count)
		success = NO;

	return success;
}

size_t ext_addIndexedIvar (Class aClass, size_t ivarSize, size_t ivarAlignment) {
	NSUInteger offset;

	/*
	 * set up an autorelease pool in case any Cocoa classes invoke +initialize
	 * during this process
	 */
	@autoreleasepool {
		NSNumber *num = objc_getAssociatedObject(aClass, kIndexedIvarSizeKey);
		offset = [num unsignedIntegerValue];

		// align to ivarAlignment
		if ((offset & (ivarAlignment - 1)) != 0) {
			// round up to a multiple of ivarAlignment
			offset = (offset & (ivarAlignment - 1)) + ivarAlignment;
		}

		num = [NSNumber numberWithUnsignedInteger:offset + ivarSize];
		objc_setAssociatedObject(aClass, kIndexedIvarSizeKey, num, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

		Method allocWithZone = class_getClassMethod(aClass, @selector(allocWithZone:));
		if (method_getImplementation(allocWithZone) != (IMP)&ext_allocWithZonePlusIndexedIvars) {
			class_replaceMethod(
				object_getClass(aClass),
				@selector(allocWithZone:),
				(IMP)&ext_allocWithZonePlusIndexedIvars,
				method_getTypeEncoding(allocWithZone)
			);
		}
	}

	return offset;
}

Class ext_classBeforeSuperclass (Class receiver, Class superclass) {
	Class previousClass = nil;

	while (![receiver isEqual:superclass]) {
		previousClass = receiver;
		receiver = class_getSuperclass(receiver);
	}

	return previousClass;
}

Class *ext_copyClassList (unsigned *count) {
	// get the number of classes registered with the runtime
	int classCount = objc_getClassList(NULL, 0);
	if (!classCount) {
		if (count)
			*count = 0;

		return NULL;
	}

	// allocate space for them plus NULL
	Class *allClasses = malloc(sizeof(Class) * (classCount + 1));
	if (!allClasses) {
		fprintf(stderr, "ERROR: Could allocate memory for all classes\n");
		if (count)
			*count = 0;

		return NULL;
	}

	// and then actually pull the list of the class objects
	classCount = objc_getClassList(allClasses, classCount);
	allClasses[classCount] = NULL;

	if (count)
		*count = (unsigned)classCount;

	return allClasses;
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

BOOL ext_addMethodsFromClass (Class srcClass, Class dstClass, BOOL checkSuperclasses, ext_failedMethodCallback failedToAddCallback) {
	ext_methodInjectionBehavior behavior = ext_methodInjectionFailOnExisting;
	if (checkSuperclasses)
		behavior |= ext_methodInjectionFailOnSuperclassExisting;
	
	return ext_injectMethodsFromClass(srcClass, dstClass, behavior, failedToAddCallback);
}

BOOL ext_classIsKindOfClass (Class receiver, Class aClass) {
	while (receiver) {
		if (receiver == aClass)
			return YES;

		receiver = class_getSuperclass(receiver);
	}

	return NO;
}

Class *ext_copyClassListConformingToProtocol (Protocol *protocol, unsigned *count) {
	Class *allClasses;

	/*
	 * set up an autorelease pool in case any Cocoa classes invoke +initialize
	 * during this process
	 */
	@autoreleasepool {
		unsigned classCount = 0;
		allClasses = ext_copyClassList(&classCount);

		// we're going to reuse allClasses for the return value, so returnIndex will
		// keep track of the indices we replace with new values
		unsigned returnIndex = 0;

		for (unsigned classIndex = 0;classIndex < classCount;++classIndex) {
			Class cls = allClasses[classIndex];
			if (class_conformsToProtocol(cls, protocol))
				allClasses[returnIndex++] = cls;
		}

		allClasses[returnIndex] = NULL;
		if (count)
			*count = returnIndex;
	}
	
	return allClasses;
}

ext_propertyAttributes *ext_copyPropertyAttributes (objc_property_t property) {
	const char * const attrString = property_getAttributes(property);
	if (!attrString) {
		fprintf(stderr, "ERROR: Could not get attribute string from property %s\n", property_getName(property));
		return NULL;
	}

	if (attrString[0] != 'T') {
		fprintf(stderr, "ERROR: Expected attribute string \"%s\" for property %s to start with 'T'\n", attrString, property_getName(property));
		return NULL;
	}

	const char *typeString = attrString + 1;
	const char *next = NSGetSizeAndAlignment(typeString, NULL, NULL);
	if (!next) {
		fprintf(stderr, "ERROR: Could not read past type in attribute string \"%s\" for property %s\n", attrString, property_getName(property));
		return NULL;
	}

	size_t typeLength = next - typeString;
	if (!typeLength) {
		fprintf(stderr, "ERROR: Invalid type in attribute string \"%s\" for property %s\n", attrString, property_getName(property));
		return NULL;
	}

	if (*next != '\0') {
		// skip past any junk before the first flag
		next = strchr(next, ',');
	}

	// allocate enough space for the structure and the type string (plus a NUL)
	ext_propertyAttributes *attributes = calloc(1, sizeof(ext_propertyAttributes) + typeLength + 1);
	if (!attributes) {
		fprintf(stderr, "ERROR: Could not allocate ext_propertyAttributes structure for attribute string \"%s\" for property %s\n", attrString, property_getName(property));
		return NULL;
	}

	// copy the type string
	strncpy(attributes->type, typeString, typeLength);
	attributes->type[typeLength] = '\0';

	while (*next == ',') {
		char flag = next[1];
		next += 2;

		switch (flag) {
		case '\0':
			break;

		case 'R':
			attributes->readonly = YES;
			break;

		case 'C':
			attributes->memoryManagementPolicy = ext_propertyMemoryManagementPolicyCopy;
			break;

		case '&':
			attributes->memoryManagementPolicy = ext_propertyMemoryManagementPolicyRetain;
			break;

		case 'N':
			attributes->nonatomic = YES;
			break;

		case 'G':
		case 'S':
			{
				const char *nextFlag = strchr(next, ',');
				SEL name = NULL;

				if (!nextFlag) {
					// assume that the rest of the string is the selector
					const char *selectorString = next;
					next = "";

					name = sel_registerName(selectorString);
				} else {
					size_t selectorLength = nextFlag - next;
					if (!selectorLength) {
						fprintf(stderr, "ERROR: Found zero length selector name in attribute string \"%s\" for property %s\n", attrString, property_getName(property));
						goto errorOut;
					}

					char selectorString[selectorLength + 1];

					strncpy(selectorString, next, selectorLength);
					selectorString[selectorLength] = '\0';

					name = sel_registerName(selectorString);
					next = nextFlag;
				}

				if (flag == 'G')
					attributes->getter = name;
				else
					attributes->setter = name;
			}

			break;

		case 'D':
			attributes->dynamic = YES;
			attributes->ivar = NULL;
			break;

		case 'V':
			// assume that the rest of the string (if present) is the ivar name
			if (*next == '\0') {
				// if there's nothing there, let's assume this is dynamic
				attributes->ivar = NULL;
			} else {
				attributes->ivar = next;
				next = "";
			}

			break;

		case 'W':
			attributes->weak = YES;
			break;

		case 'P':
			attributes->canBeCollected = YES;
			break;

		case 't':
			fprintf(stderr, "ERROR: Old-style type encoding is unsupported in attribute string \"%s\" for property %s\n", attrString, property_getName(property));

			// skip over this type encoding
			while (*next != ',' && *next != '\0')
				++next;

			break;

		default:
			fprintf(stderr, "ERROR: Unrecognized attribute string flag '%c' in attribute string \"%s\" for property %s\n", flag, attrString, property_getName(property));
		}
	}

	if (*next != '\0') {
		fprintf(stderr, "Warning: Unparsed data \"%s\" in attribute string \"%s\" for property %s\n", next, attrString, property_getName(property));
	}

	if (!attributes->getter) {
		// use the property name as the getter by default
		attributes->getter = sel_registerName(property_getName(property));
	}

	if (!attributes->setter) {
		const char *propertyName = property_getName(property);
		size_t propertyNameLength = strlen(propertyName);

		// we want to transform the name to setProperty: style
		size_t setterLength = propertyNameLength + 4;

		char setterName[setterLength + 1];
		strncpy(setterName, "set", 3);
		strncpy(setterName + 3, propertyName, propertyNameLength);

		// capitalize property name for the setter
		setterName[3] = toupper(setterName[3]);

		setterName[setterLength - 1] = ':';
		setterName[setterLength] = '\0';

		attributes->setter = sel_registerName(setterName);
	}

	return attributes;

errorOut:
	free(attributes);
	return NULL;
}

Class *ext_copySubclassList (Class targetClass, unsigned *subclassCount) {
	unsigned classCount = 0;
	Class *allClasses = ext_copyClassList(&classCount);
	if (!allClasses || !classCount) {
		fprintf(stderr, "ERROR: No classes registered with the runtime, cannot find %s!\n", class_getName(targetClass));
		return NULL;
	}

	// we're going to reuse allClasses for the return value, so returnIndex will
	// keep track of the indices we replace with new values
	unsigned returnIndex = 0;

	BOOL isMeta = class_isMetaClass(targetClass);

	for (unsigned classIndex = 0;classIndex < classCount;++classIndex) {
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
		*subclassCount = returnIndex;
	
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

BOOL ext_getPropertyAccessorsForClass (objc_property_t property, Class aClass, Method *getter, Method *setter) {
	ext_propertyAttributes *attributes = ext_copyPropertyAttributes(property);
	if (!attributes)
		return NO;

	SEL getterName = attributes->getter;
	SEL setterName = attributes->setter;
	
	free(attributes);
	attributes = NO;

	/*
	 * set up an autorelease pool in case this sends aClass its first message
	 */
	@autoreleasepool {
		Method foundGetter = class_getInstanceMethod(aClass, getterName);
		if (!foundGetter) {
			return NO;
		}
		
		if (getter)
			*getter = foundGetter;

		if (setter) {
			Method foundSetter = class_getInstanceMethod(aClass, setterName);
			if (foundSetter)
				*setter = foundSetter;
		}
	}
	
	return YES;
}

NSMethodSignature *ext_globalMethodSignatureForSelector (SEL aSelector) {
	unsigned classCount = 0;
	Class *classes = ext_copyClassList(&classCount);
	if (!classes)
		return nil;

	NSMethodSignature *signature = nil;

	/*
	 * set up an autorelease pool in case any Cocoa classes invoke +initialize
	 * during this process
	 */
	@autoreleasepool {
		Class proxyClass = objc_getClass("NSProxy");
		SEL selectorsToTry[] = {
			@selector(methodSignatureForSelector:),
			@selector(instanceMethodSignatureForSelector:)
		};

		for (unsigned i = 0;i < classCount;++i) {
			Class cls = classes[i];

			// NSProxy crashes if you send it a meaningful message, like
			// methodSignatureForSelector:
			if (ext_classIsKindOfClass(cls, proxyClass))
				continue;

			for (size_t selIndex = 0;selIndex < sizeof(selectorsToTry) / sizeof(*selectorsToTry);++selIndex) {
				SEL lookupSel = selectorsToTry[selIndex];
				Method methodSignatureForSelector = class_getClassMethod(cls, lookupSel);

				if (methodSignatureForSelector) {
					methodSignatureForSelectorIMP impl = (methodSignatureForSelectorIMP)method_getImplementation(methodSignatureForSelector);
					signature = impl(cls, lookupSel, aSelector);
					
					if (signature)
						break;
				}
			}

			if (signature)
				break;
		}
	}

	free(classes);
	return signature;
}

void ext_removeMethod (Class aClass, SEL methodName) {
	Method existingMethod = ext_getImmediateInstanceMethod(aClass, methodName);
	if (!existingMethod) {
		return;
	}

	/*
	 * set up an autorelease pool in case any Cocoa classes invoke +initialize
	 * during this process
	 */
	@autoreleasepool {
		Method superclassMethod = NULL;
		Class superclass = class_getSuperclass(aClass);
		if (superclass)
			superclassMethod = class_getInstanceMethod(superclass, methodName);
		
		if (superclassMethod) {
			method_setImplementation(existingMethod, method_getImplementation(superclassMethod));
		} else {
			// since we now know that the method doesn't exist on any
			// superclass, get an IMP internal to the runtime for message forwarding
			IMP forward = class_getMethodImplementation(superclass, methodName);

			method_setImplementation(existingMethod, forward);
		}
	}
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

void ext_replaceMethodsFromClass (Class srcClass, Class dstClass) {
	ext_injectMethodsFromClass(srcClass, dstClass, ext_methodInjectionReplace, NULL);
}

