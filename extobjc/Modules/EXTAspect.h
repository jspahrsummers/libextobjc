//
//  EXTAspect.h
//  extobjc
//
//  Created by Justin Spahr-Summers on 24.11.11.
//  Released into the public domain.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "metamacros.h"

/**
 * Declares an aspect \a NAME.
 *
 * To apply this aspect to a class, declare the class to conform to a protocol
 * \a NAME. This also works with categories, to extend existing classes with
 * aspects.
 *
 * @code

@aspect(Logger);

@interface BankAccount : NSObject <Logger> {
}

- (void)deposit:(NSDecimalNumber *)amount;
- (void)withdraw:(NSDecimalNumber *)amount;
@end

@interface BankAccount (TransactionExtensions) <Transaction>
@end

 * @endcode
 */
#define aspect(NAME) \
    protocol NAME <NSObject> \
    @end

/**
 * Defines the implementation of aspect \a NAME. The aspect can contain any
 * number of methods matching the following type signature:
 *
 * @code
+ (void)advise:(void (^)(void))body;
- (void)advise:(void (^)(void))body;
 * @endcode
 *
 * The name of the first parameter (\c advise: in the example) specifies the
 * pointcut, or how the advice is applied to an instance or class. The following
 * pointcuts are currently defined:
 *
 * @li \c advise: is invoked for every method that is called on the object.
 *
 * In all cases, \c self and \c _cmd are respectively the object and the
 * selector upon which the advice is being applied. Explicitly invoking \c _cmd
 * against \c self from within an advice method will result in undefined
 * behavior.
 */
#define aspectimplementation(NAME) \
    interface NAME ## _AspectContainer : NSObject {} \
    @end \
    \
    @implementation NAME ## _AspectContainer \
	/*
	 * when this class is loaded into the runtime, add the aspect into the list
	 */ \
	+ (void)load { \
		/*
		 * passes the actual protocol as the first parameter, then this class as
		 * the second
		 */ \
		if (!ext_addAspect(objc_getProtocol(metamacro_stringify(NAME)), self)) \
            fprintf(stderr, "ERROR: Could not load aspect %s\n", metamacro_stringify(NAME)); \
	} \
	\
	/*
	 * using the "constructor" function attribute, we can ensure that this
	 * function is executed only AFTER all the Objective-C runtime setup (i.e.,
	 * after all +load methods have been executed)
	 */ \
	__attribute__((constructor)) \
	static void ext_ ## NAME ## _inject (void) { \
		/*
		 * use this injection point to mark this aspect as ready for loading
		 */ \
		ext_loadAspect(objc_getProtocol(metamacro_stringify(NAME))); \
	}

/*** implementation details follow ***/
BOOL ext_addAspect (Protocol *protocol, Class methodContainer);
void ext_loadAspect (Protocol *protocol);

