/*
 *  EXTProtocolCategory.h
 *  extobjc
 *
 *  Created by Justin Spahr-Summers on 2010-11-13.
 *  Released into the public domain.
 */

#import <objc/runtime.h>
#import <stdio.h>

#define pcategoryinterface(PROTOCOL, CATEGORY) \
	interface NSObject (CATEGORY)

#define pcategoryimplementation(PROTOCOL, CATEGORY) \
	interface PROTOCOL ## _ ## CATEGORY ## _MethodContainer : NSObject {} \
	@end \
	\
	@implementation PROTOCOL ## _ ## CATEGORY ## _MethodContainer \
	/*
	 * when this class is loaded into the runtime, add the protocol category
	 * into the list we have of them
	 */ \
	+ (void)load { \
		/*
		 * passes the actual protocol as the first parameter, then this class as
		 * the second
		 */ \
		if (!ext_addProtocolCategory(objc_getProtocol(# PROTOCOL), self)) \
			fprintf(stderr, "ERROR: Could not load protocol category %s (%s)\n", # PROTOCOL, # CATEGORY); \
	} \
	\
	/*
	 * using the "constructor" function attribute, we can ensure that this
	 * function is executed only AFTER all the Objective-C runtime setup (i.e.,
	 * after all +load methods have been executed)
	 */ \
	__attribute__((constructor)) \
	static void ext_ ## PROTOCOL ## _ ## CATEGORY ## _inject (void) { \
		/*
		 * use this injection point to mark this protocol category as ready for
		 * loading
		 */ \
		ext_loadProtocolCategory(objc_getProtocol(# PROTOCOL)); \
	}

/*** implementation details follow ***/
BOOL ext_addProtocolCategory (Protocol *protocol, Class methodContainer);
void ext_loadProtocolCategory (Protocol *protocol);

