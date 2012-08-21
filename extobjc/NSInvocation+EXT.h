//
//  NSInvocation+EXT.h
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-03-11.
//  Copyright (C) 2012 Justin Spahr-Summers.
//  Released under the MIT license.
//

#import <Foundation/Foundation.h>

@interface NSInvocation (EXTExtensions)
/**
 * Using the variadic arguments in \a args, initializes the arguments of this
 * invocation starting at index 2 (after 'self' and '_cmd'). The argument types
 * are determined using the invocation's method signature.
 *
 * Returns \c NO if an error occurs (such as being unable to retrieve an
 * argument for a certain type).
 *
 * @warning Due to the mechanics behind variable argument lists, this method cannot
 * be used with method signatures that involve \c struct or \c union parameters.
 * Blocks and function pointers may or may not also cause problems. Such
 * arguments must be set individually.
 */
- (BOOL)setArgumentsFromArgumentList:(va_list)args;
@end
