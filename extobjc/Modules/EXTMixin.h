/*
 *  EXTMixin.h
 *  extobjc
 *
 *  Created by Justin Spahr-Summers on 2010-11-10.
 *  Released into the public domain.
 */

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

/**
 * "Mixes in" the class and instance methods of \a CLASS into pre-existing class
 * \a TARGET. Only the methods of \a CLASS itself, and not any superclasses, are mixed
 * in. Any methods by the same name in \a TARGET are overwritten.
 *
 * This macro should be placed at file scope in an implementation file.
 *
 * @note The mixing in occurs only after all +load methods in the image have been
 * executed.
 */
#define EXTMixin(TARGET, CLASS) \
	__attribute__((constructor)) \
	static void ext_ ## TARGET ## _ ## CLASS ## _mixin (void) { \
		Class targetClass = objc_getClass(# TARGET); \
		Class sourceClass = objc_getClass(# CLASS); \
		\
		unsigned imethodCount = 0; \
		Method *imethodList = class_copyMethodList(sourceClass, &imethodCount); \
		\
		unsigned cmethodCount = 0; \
		Method *cmethodList = class_copyMethodList(object_getClass(sourceClass), &cmethodCount); \
		\
		if (!imethodCount && !cmethodCount) \
			return; \
		\
		for (unsigned methodIndex = 0;methodIndex < imethodCount;++methodIndex) { \
			Method method = imethodList[methodIndex]; \
			SEL selector = method_getName(method); \
			IMP imp = method_getImplementation(method); \
			const char *types = method_getTypeEncoding(method); \
			\
			class_replaceMethod(targetClass, selector, imp, types); \
		} \
		\
		Class metaclass = object_getClass(targetClass); \
		for (unsigned methodIndex = 0;methodIndex < cmethodCount;++methodIndex) { \
			Method method = cmethodList[methodIndex]; \
			SEL selector = method_getName(method); \
			IMP imp = method_getImplementation(method); \
			const char *types = method_getTypeEncoding(method); \
			\
			class_replaceMethod(metaclass, selector, imp, types); \
		} \
	}

