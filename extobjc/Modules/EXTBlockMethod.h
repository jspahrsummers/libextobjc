//
//  EXTBlockMethod.h
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-03-11.
//  Released into the public domain.
//

#import <objc/runtime.h>

/**
 * Constructs a block suitable for use as a method implementation, using the
 * given argument list as the arguments for the method. This is meant to be used
 * in a style similar to the normal \c ^ syntax:
 * 
 * @code
id badIsEqual = blockMethod(id obj){
	return obj != nil;
};
 * @endcode
 *
 * \c _cmd will be declared for your block, and, when invoked as a method
 * implementation, will be initialized to the selector of the method.
 *
 * @todo This macro does not yet declare \c self.
 */
#define blockMethod(...) \
	^(SEL _cmd, __VA_ARGS__)

/**
 * Uses \a block as the implementation for a new method \a name on \a aClass. \a
 * types describes the return and argument types of the method. \a block must
 * have been originally defined using #blockMethod. This will not overwrite an
 * existing method by the same name on \a aClass.
 *
 * Returns \c YES if the method was added successfully, or \c NO if it was not
 * (such as due to a naming conflict).
 */
BOOL ext_addBlockMethod (Class aClass, SEL name, id block, const char *types);

/**
 * Returns the implementation of \a block as an \c IMP, suitable for use as
 * a method implementation. Note that this does not (and cannot do) any argument
 * checking to ensure that \a block meets the requirements for an Objective-C
 * method -- that is the responsibility of the caller.
 */
IMP ext_blockImplementation (id block);

/*** implementation details follow ***/

