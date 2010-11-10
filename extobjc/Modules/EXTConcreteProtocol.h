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

/**
 * Used to list methods with concrete implementations within a \@protocol
 * definition.
 */
#define concrete \
	optional

/**
 * Defines a "concrete protocol," which can provide default implementations of
 * methods within protocol \a NAME. A \@protocol block should exist in a header
 * file, and a corresponding \@concreteprotocol block in an implementation file.
 * Any object that declares itself to conform to protocol \a NAME will receive
 * its method implementations \e only if no method by the same name already
 * exists.
 *
 * @code
 *

@protocol MyProtocol
@required
	- (void)someRequiredMethod;

@optional
	- (void)someOptionalMethod;

@concrete
	- (BOOL)isConcrete;

@end

 *
 * @endcode
 * @code
 *

@concreteprotocol(MyProtocol)
- (BOOL)isConcrete {
  	return YES;
}

@end

 *
 * @endcode
 */
#define concreteprotocol(NAME) \
	interface NAME ## _MethodContainer : NSObject {} \
	@end \
	\
	@implementation NAME ## _MethodContainer \
	\
	__attribute__((constructor)) \
	static void ext_ ## NAME ## _inject (void) { \
		Protocol *protocol = objc_getProtocol(# NAME); \
		if (!protocol) { \
			NSLog(@"ERROR: Concrete protocol %s does not have a corresponding @protocol interface", # NAME); \
			return; \
		} \
		\
		Class containerClass = objc_getClass(metamacro_stringify(NAME ## _MethodContainer)); \
		if (!containerClass) { \
			NSLog(@"ERROR: Could not locate methods for concrete protocol %s", # NAME); \
			return; \
		} \
		\
		unsigned imethodCount = 0; \
		Method *imethodList = class_copyMethodList(containerClass, &imethodCount); \
		\
		unsigned cmethodCount = 0; \
		Method *cmethodList = class_copyMethodList(object_getClass(containerClass), &cmethodCount); \
		\
		if (!imethodCount && !cmethodCount) \
			return; \
		\
		int classCount = objc_getClassList(NULL, 0); \
		Class *allClasses = malloc(sizeof(Class) * classCount); \
		if (!allClasses) { \
			free(imethodList); \
			free(cmethodList); \
			\
			NSLog(@"ERROR: Could not obtain list of all classes"); \
			return; \
		} \
		\
		classCount = objc_getClassList(allClasses, classCount); \
		for (int classIndex = 0;classIndex < classCount;++classIndex) { \
			Class class = allClasses[classIndex]; \
			if (!class_conformsToProtocol(class, protocol)) \
				continue; \
			\
			for (unsigned methodIndex = 0;methodIndex < imethodCount;++methodIndex) { \
				Method method = imethodList[methodIndex]; \
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
				if (!class_addMethod(class, selector, imp, types)) { \
					NSLog(@"ERROR: Could not implement instance method %@ from concrete protocol %s on class %@", \
						NSStringFromSelector(selector), # NAME, class); \
				} \
			} \
			\
			Class metaclass = object_getClass(class); \
			for (unsigned methodIndex = 0;methodIndex < cmethodCount;++methodIndex) { \
				Method method = cmethodList[methodIndex]; \
				SEL selector = method_getName(method); \
				\
				/* this actually checks for class methods (instance of the
				 * metaclass) */ \
				if (class_getInstanceMethod(metaclass, selector)) { \
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
				if (!class_addMethod(metaclass, selector, imp, types)) { \
					NSLog(@"ERROR: Could not implement class method %@ from concrete protocol %s on class %@", \
						NSStringFromSelector(selector), # NAME, metaclass); \
				} \
			} \
		} \
		\
		free(imethodList); \
		free(cmethodList); \
		free(allClasses); \
	}

