/*
 *  EXTConcreteProtocol.h
 *  extobjc
 *
 *  Created by Justin Spahr-Summers on 2010-11-09.
 *  Released into the public domain.
 */

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "metamacros.h"

#define concreteprotocol(NAME) \
	interface NAME ## _MethodContainer {} \
	@end \
	\
	@implementation NAME ## _MethodContainer \
	\
	__attribute__((constructor)) void NAME ## _inject (void) { \
		NSLog(@"loading concrete protocol %s", # NAME); \
		\
		Protocol *protocol = objc_getProtocol(# NAME); \
		if (!protocol) { \
			NSLog(@"Concrete protocol %s does not have a corresponding @protocol interface, cannot load", # NAME); \
			return; \
		} \
		\
		unsigned methodCount = 0; \
		Method *methodList = class_copyMethodList(objc_getClass(metamacro_stringify(NAME ## _MethodContainer)), &methodCount); \
		\
		if (!methodList || !methodCount) { \
			free(methodList); \
			\
			NSLog(@"No methods in concrete protocol %s", # NAME); \
			return; \
		} \
		\
		int classCount = objc_getClassList(NULL, 0); \
		Class *allClasses = malloc(sizeof(Class) * classCount); \
		if (!allClasses) { \
			free(methodList); \
			\
			NSLog(@"Could not obtain list of all classes"); \
			return; \
		} \
		\
		classCount = objc_getClassList(allClasses, classCount); \
		for (int classIndex = 0;classIndex < classCount;++classIndex) { \
			Class class = allClasses[classIndex]; \
			if (!class_conformsToProtocol(class, protocol)) \
				continue; \
			\
			NSLog(@"Found class %@ conforming to concrete protocol %s", class, # NAME); \
			for (unsigned methodIndex = 0;methodIndex < methodCount;++methodIndex) { \
				Method method = methodList[methodIndex]; \
				SEL selector = method_getName(method); \
				\
				if (class_getInstanceMethod(class, selector)) { \
					/*
					 * don't override implementations, even those of
					 * a superclass
					 */ \
					continue; \
				} \
				\
				IMP imp = method_getImplementation(method); \
				const char *types = method_getTypeEncoding(method); \
				\
				class_addMethod(class, selector, imp, types); \
			} \
		} \
		\
		free(methodList); \
		free(allClasses); \
	}

