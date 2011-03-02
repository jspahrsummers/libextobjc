//
//  EXTFinalMethod.h
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-03-02.
//  Released into the public domain.
//

#import <objc/runtime.h>
#import "metamacros.h"

/**
 * Declares \a METHOD, which should be an instance method, in \a class, as being final,
 * unable to be overridden. If \c DEBUG is defined and \c NDEBUG is not defined, any
 * overriding of final methods will abort the application at startup; otherwise, any
 * overriding is simply logged and execution continues using the overriding
 * behavior.
 */
#define finalInstanceMethod(CLASS, METHOD) \
	/*
	 * using the "constructor" function attribute, we can ensure that this
	 * function is executed only AFTER all the Objective-C runtime setup (i.e.,
	 * after all +load methods have been executed)
	 */ \
	__attribute__((constructor)) \
	static void metamacro_concat(ext_checkFinalMethods_, __LINE__) (void) { \
		Class targetClass = objc_getClass(metamacro_stringify(CLASS)); \
		if (!ext_verifyFinalMethod(@selector(METHOD), targetClass)) \
			ext_finalMethodFailed(CLASS, METHOD); \
	}

/**
 * Declares \a METHOD, which should be a class method, in \a class, as being final,
 * unable to be overridden. If \c DEBUG is defined and \c NDEBUG is not defined, any
 * overriding of final methods will abort the application at startup; otherwise, any
 * overriding is simply logged and execution continues using the overriding
 * behavior.
 */
#define finalClassMethod(CLASS, METHOD) \
	/*
	 * using the "constructor" function attribute, we can ensure that this
	 * function is executed only AFTER all the Objective-C runtime setup (i.e.,
	 * after all +load methods have been executed)
	 */ \
	__attribute__((constructor)) \
	static void metamacro_concat(ext_checkFinalMethods_, __LINE__) (void) { \
		Class targetClass = objc_getClass(metamacro_stringify(CLASS)); \
		\
		targetClass = object_getClass(targetClass); \
		if (!ext_verifyFinalMethod(@selector(METHOD), targetClass)) \
			ext_finalMethodFailed(CLASS, METHOD); \
	}

/*** implementation details follow ***/
BOOL ext_verifyFinalMethod (SEL methodName, Class targetClass);

// if this is a debug build...
#if defined(DEBUG) && !defined(NDEBUG)
	// abort if a final method is overridden
	#define ext_finalMethodFailed(CLASS, METHOD) \
		abort()
#else
	// otherwise, do nothing (the error message is printed in
	// ext_verifyFinalMethod)
	#define ext_finalMethodFailed(CLASS, METHOD)
#endif
