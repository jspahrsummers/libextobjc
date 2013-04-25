//
//  EXTBlockMethod.h
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-03-11.
//  Copyright (C) 2012 Justin Spahr-Summers.
//  Released under the MIT license.
//

#import <objc/runtime.h>
#import "EXTRuntimeExtensions.h"

/**
 * The type for a block-based property getter. A block declared as this type may
 * not actually return a value of type \c id. Instead, it should be taken
 * similarly to \c objc_msgSend, where the block should be cast to the proper
 * type before invocation.
 */
typedef id (^ext_blockGetter)(id);

/**
 * The type for a block-based property setter. A block declared as this type may
 * not actually accept a value of type \c id. Instead, it should be taken
 * similarly to \c objc_msgSend, where the block should be cast to the proper
 * type before invocation.
 */
typedef void (^ext_blockSetter)(id, id);

/**
 * Uses \a block as the implementation for a new method \a name on \a aClass. \a
 * types describes the return and argument types of the method. This will not
 * overwrite an existing method by the same name on \a aClass.
 *
 * Returns \c YES if the method was added successfully, or \c NO if it was not
 * (such as due to a naming conflict).
 */
BOOL ext_addBlockMethod (Class aClass, SEL name, id block, const char *types);

/**
 * If \a block has a type signature, this will return a sanitized copy of the
 * signature, suitable for use as a method's type encoding. Not all blocks have
 * type signatures -- if \a block does not or its type signature is invalid, \c
 * NULL is returned. You must \c free() the returned string when you are
 * finished.
 */
char *ext_copyBlockTypeEncoding (id block);

/**
 * Replaces the implementation of \a name on \a aClass using \a block. \a
 * types describes the return and argument types of the method. This will
 * overwrite any existing method by the same name on \a aClass.
 */
void ext_replaceBlockMethod (Class aClass, SEL name, id block, const char *types);

/**
 * Synthesizes blocks for a property getter and setter of \a type, which are
 * returned in \a getter and \a setter, respectively. If \a type denotes an
 * object type, \a memoryManagementPolicy determines the retention policy for
 * the setter. If \a atomic is \c YES, the generated getter and setter will read
 * and write atomically.
 *
 * Neither \a getter and \a setter should be \c NULL. Both are autoreleased by
 * default.
 *
 * @note \a type should be an Objective-C type encoding, such as the result of
 * an \c @encode() directive.
 */
void ext_synthesizeBlockProperty (const char *type, ext_propertyMemoryManagementPolicy memoryManagementPolicy, BOOL atomic, ext_blockGetter *getter, ext_blockSetter *setter);

