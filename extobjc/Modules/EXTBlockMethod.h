//
//  EXTBlockMethod.h
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-03-11.
//  Released into the public domain.
//

#import <objc/runtime.h>
#import "EXTRuntimeExtensions.h"

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
 * implementation, will be initialized to the selector of the method. Your block
 * must have at least one argument, the first of which is the object upon which
 * the block is being invoked.
 */
#define blockMethod(...) \
	^(SEL _cmd, __VA_ARGS__)

/**
 * The type for a block-based property getter.
 */
typedef id (^ext_blockGetter)(void);

/**
 * The type for a block-based property setter.
 */
typedef void (^ext_blockSetter)(id);

/**
 * Uses \a block as the implementation for a new method \a name on \a aClass. \a
 * types describes the return and argument types of the method. \a block must
 * have been originally defined using #blockMethod. This will not overwrite an
 * existing method by the same name on \a aClass.
 *
 * Returns \c YES if the method was added successfully, or \c NO if it was not
 * (such as due to a naming conflict).
 *
 * @bug This will only work if the block doesn't require context!
 */
BOOL ext_addBlockMethod (Class aClass, SEL name, id block, const char *types);

/**
 * Returns the implementation of \a block as an \c IMP, suitable for use as
 * a method implementation. Note that this does not (and cannot do) any argument
 * checking to ensure that \a block meets the requirements for an Objective-C
 * method -- that is the responsibility of the caller.
 *
 * @note On Mac OS X 10.7 or iOS 4.3, a public \c imp_implementationWithBlock()
 * function is available that supersedes the functionality of this one.
 */
IMP ext_blockImplementation (id block);

/**
 * Replaces the implementation of \a name on \a aClass using \a block. \a
 * types describes the return and argument types of the method. \a block must
 * have been originally defined using #blockMethod. This will overwrite any
 * existing method by the same name on \a aClass.
 *
 * @bug This will only work if the block doesn't require context!
 */
void ext_replaceBlockMethod (Class aClass, SEL name, id block, const char *types);

/**
 * Synthesizes blocks for a property getter and a property setter, which are
 * returned in \a getter and \a setter, respectively. \a memoryManagementPolicy
 * determines the retention policy for any objects passed into the setter. If \a
 * atomic is \c YES, the generated getter and setter will read and write
 * atomically.
 *
 * Neither \a getter and \a setter should be \c NULL. Both are autoreleased by
 * default.
 */
void ext_synthesizeBlockProperty (ext_propertyMemoryManagementPolicy memoryManagementPolicy, BOOL atomic, ext_blockGetter *getter, ext_blockSetter *setter);

