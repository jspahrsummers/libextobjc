//
//  EXTMaybe.h
//  extobjc
//
//  Created by Justin Spahr-Summers on 21.01.12.
//  Copyright (C) 2012 Justin Spahr-Summers.
//  Released under the MIT license.
//

#import <Foundation/Foundation.h>

/**
 * Behaves like an \c NSError object, but treats unrecognized selectors like
 * messages sent to \c nil.
 *
 * This class allows methods to eschew the typical \c NSError argument, and
 * instead return the successful result or the error that occurred (which will
 * appear to be \c nil to any code that tries to make use of it).
 */
@interface EXTMaybe : NSProxy

/**
 * Returns an object which behaves like the given error when sent \c NSError
 * messages, or behaves like \c nil (using #EXTNil) when sent anything else.
 */
+ (id)maybeWithError:(NSError *)error;

/**
 * If \a maybe is a valid object -- meaning an object which is not an \c
 * NSError, \c NSNull, or #EXTNil -- that object is returned.
 *
 * Otherwise, if \a block is not \c nil, it is executed, and the result of the
 * block is returned from the method. If \a maybe is specifically an \c NSError,
 * that error is passed into the block; otherwise, the argument will be \c nil.
 * If \a block is \c nil, this method returns \c nil.
 */
+ (id)validObjectWithMaybe:(id)maybe orElse:(id (^)(NSError *))block;

@end
