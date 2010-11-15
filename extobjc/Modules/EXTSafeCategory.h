/*
 *  EXTSafeCategory.h
 *  extobjc
 *
 *  Created by Justin Spahr-Summers on 2010-11-13.
 *  Released into the public domain.
 */

#import <objc/runtime.h>
#import "metamacros.h"

/**
 * Defines the implementation of a safe category named \a CATEGORY on \a CLASS.
 * A safe category will only add methods to \a CLASS if a method by the same
 * name does not already exist (\e not including superclasses). If \c DEBUG is
 * defined and \c NDEBUG is not defined, any method conflicts will abort the
 * application at startup; otherwise, any method conflicts are simply logged,
 * and no overwriting occurs.
 *
 * This macro should be used in implementation files. Normal \@interface blocks
 * can be used in header files to declare safe categories, as long as the name
 * given in parentheses matches \a CATEGORY.
 *
 * @bug Due to an implementation detail, methods invoked against \c super will
 * actually be invoked against \c self.
 */
#define safecategory(CLASS, CATEGORY) \
	interface CLASS ## _ ## CATEGORY ## _MethodContainer : CLASS {} \
	@end \
	\
	@implementation CLASS ## _ ## CATEGORY ## _MethodContainer \
	/*
	 * using the "constructor" function attribute, we can ensure that this
	 * function is executed only AFTER all the Objective-C runtime setup (i.e.,
	 * after all +load methods have been executed)
	 */ \
	__attribute__((constructor)) \
	static void ext_ ## CLASS ## _ ## CATEGORY ## _inject (void) { \
		/*
		 * use this injection point to load the methods into the target class
		 */ \
		const char *className_ = metamacro_stringify(CLASS ## _ ## CATEGORY ## _MethodContainer); \
		if (!ext_loadSafeCategory(objc_getClass(className_))) {\
			ext_safecategory_failed(CLASS, CATEGORY); \
		} \
	}

/*** implementation details follow ***/
BOOL ext_loadSafeCategory (Class methodContainer);

#if defined(DEBUG) && !defined(NDEBUG)
	// abort in debug builds if a safe category fails to load
	#define ext_safecategory_failed(CLASS, CATEGORY) \
		abort()
#else
	// in release builds, print an error message
	#define ext_safecategory_failed(CLASS, CATEGORY) \
		fprintf(stderr, "ERROR: Failed to fully load safe category %s (%s)\n", # CLASS, # CATEGORY)
#endif

