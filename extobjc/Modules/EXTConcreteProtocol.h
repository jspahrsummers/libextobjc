/*
 *  EXTConcreteProtocol.h
 *  extobjc
 *
 *  Created by Justin Spahr-Summers on 2010-11-09.
 *  Released into the public domain.
 */

#import <objc/runtime.h>
#import <stdio.h>
#import "metamacros.h"

/**
 * Used to list methods with concrete implementations within a \@protocol
 * definition.
 *
 * Semantically, this is equivalent to using \@optional, but is recommended for
 * documentation reasons. Although concrete protocol methods are optional in the
 * sense that conforming objects don't need to implement them, they are,
 * however, always guaranteed to be present.
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

// MyProtocol.h
@protocol MyProtocol
@required
	- (void)someRequiredMethod;

@optional
	- (void)someOptionalMethod;

@concrete
	- (BOOL)isConcrete;

@end

// MyProtocol.m
@concreteprotocol(MyProtocol)
- (BOOL)isConcrete {
  	return YES;
}

@end

 * @endcode
 *
 * @warning You should not invoke methods against \c super in the implementation
 * of a concrete protocol, as the superclass may not be the type you expect (and
 * may not even inherit from \c NSObject).
 */
#define concreteprotocol(NAME) \
	/*
	 * create a class that simply contains all the methods used in this protocol
	 *
	 * it also conforms to the protocol itself, to help with static typing (for
	 * instance, calling another protocol'd method on self) – this doesn't cause
	 * any problems with the injection, since it's always done non-destructively
	 */ \
	interface NAME ## _MethodContainer : NSObject < NAME > {} \
	@end \
	\
	@implementation NAME ## _MethodContainer \
	/*
	 * when this class is loaded into the runtime, add the concrete protocol
	 * into the list we have of them
	 */ \
	+ (void)load { \
		/*
		 * passes the actual protocol as the first parameter, then this class as
		 * the second
		 */ \
		if (!ext_addConcreteProtocol(objc_getProtocol(# NAME), self)) \
			fprintf(stderr, "ERROR: Could not load concrete protocol %s", # NAME); \
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
		 * use this injection point to mark this concrete protocol as ready for
		 * loading
		 */ \
		ext_loadConcreteProtocol(objc_getProtocol(# NAME)); \
	}

/*** implementation details follow ***/
BOOL ext_addConcreteProtocol (Protocol *protocol, Class methodContainer);
void ext_loadConcreteProtocol (Protocol *protocol);

