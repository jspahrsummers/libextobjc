/*
 *  EXTSafeCategory.h
 *  extobjc
 *
 *  Created by Justin Spahr-Summers on 2010-11-13.
 *  Released into the public domain.
 */

#import <objc/runtime.h>
#import "metamacros.h"

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
	#define ext_safecategory_failed(CLASS, CATEGORY) \
		abort()
#else
	#define ext_safecategory_failed(CLASS, CATEGORY) \
		fprintf(stderr, "ERROR: Failed to fully load safe category %s (%s)\n", # CLASS, # CATEGORY)
#endif

