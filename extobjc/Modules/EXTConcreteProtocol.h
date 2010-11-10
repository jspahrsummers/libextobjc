/*
 *  EXTConcreteProtocol.h
 *  extobjc
 *
 *  Created by Justin Spahr-Summers on 2010-11-09.
 *  Released into the public domain.
 */

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
 *
 * @warning You should not invoke methods against \c super in the implementation
 * of a concrete protocol, as the superclass may not be the type you expect (and
 * may not even inherit from \c NSObject).
 */
#define concreteprotocol(NAME) \
	interface NAME ## _MethodContainer : NSObject {} \
	@end \
	\
	@implementation NAME ## _MethodContainer \
	\
	+ (void)load { \
		if (!ext_addConcreteProtocol(objc_getProtocol(# NAME), self)) \
			fprintf(stderr, "ERROR: Could not load concrete protocol %s", # NAME); \
	} \
	\
	__attribute__((constructor)) \
	static void ext_ ## NAME ## _inject (void) { \
		ext_loadConcreteProtocol(objc_getProtocol(# NAME)); \
	}

/*** implementation details follow ***/
BOOL ext_addConcreteProtocol (Protocol *protocol, Class methodContainer);
void ext_loadConcreteProtocol (Protocol *protocol);

