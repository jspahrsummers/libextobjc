//
//  EXTDispatchObject.h
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-03-11.
//  Copyright (C) 2012 Justin Spahr-Summers.
//  Released under the MIT license.
//

#import <Foundation/Foundation.h>

/**
 * Functions as a proxy for one or more other objects of any class and forwards
 * each message to all proxied objects.
 *
 * The return value for a given message is that of the \e last object
 * successfully messaged. Objects are only messaged if they indicate that they
 * can respond to a given method. The method signature for a message is
 * determined from the \e first object that can respond to it; if the other
 * proxied objects can respond to a different signature, they are ignored.
 *
 * @note To avoid warnings about static typing, refer to instances of this class as
 * \c id or using one of the classes being proxied.
 */
@interface EXTDispatchObject : NSObject

/**
 * Returns an autoreleased object that will dispatch all messages to the provided
 * objects as they are received. The order of the objects in the argument list
 * determines the order in which method lookup and dispatch occurs.
 *
 * @note All provided objects are retained until the returned object is deallocated.
 */
+ (id)dispatchObjectForObjects:(id)firstObj, ... NS_REQUIRES_NIL_TERMINATION;

/**
 * Returns an autoreleased object that will dispatch all messages to the provided
 * objects as they are received. The order of the objects in the array determines
 * the order in which method lookup and dispatch occurs.
 *
 * @note All provided objects are retained until the returned object is deallocated.
 */
+ (id)dispatchObjectForObjectsInArray:(NSArray *)objects;

@end
