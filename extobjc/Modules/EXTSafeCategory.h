/*
 *  EXTSafeCategory.h
 *  extobjc
 *
 *  Created by Justin Spahr-Summers on 2010-11-13.
 *  Released into the public domain.
 */

#import <objc/runtime.h>

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
		if (!ext_loadSafeCategory(self)) \
			fprintf(stderr, "ERROR: Could not load safe category %s (%s)", # CLASS, # CATEGORY); \
	}

/*** implementation details follow ***/
BOOL ext_loadSafeCategory (Class methodContainer);

