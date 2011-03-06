//
//  EXTMultiObject.h
//  extobjc
//
//  Created by Justin Spahr-Summers on 2010-11-09.
//  Released into the public domain.
//

#import <Foundation/Foundation.h>

/**
 * Functions as a proxy for one or more other objects of any class and forwards
 * each message to the first proxied object that responds to it. This does not send
 * every message to each target, with some exceptions for reflection functionality
 * within the \c NSObject protocol. The result is dynamism very much like multiple
 * inheritance.
 * 
 * @note To avoid warnings about static typing, refer to instances of this class as
 * \c id or using one of the classes being proxied.
 */
@interface EXTMultiObject : NSObject {
	// a C array is used rather than an NSArray for performance reasons
	id *targets;
	NSUInteger targetCount;
}

/**
 * Returns an autoreleased object that will selectively dispatch messages to the provided
 * objects as they are received. The order of the objects in the argument list
 * determines the order in which method lookup and dispatch occurs.
 *
 * @note All provided objects are retained until the returned object is deallocated.
 *
 * @warning Lookup will not work for wrapped objects that were in a collection
 * at the time of the multi-object's initialization.
 */
+ (id)multiObjectForObjects:(id)firstObj, ... NS_REQUIRES_NIL_TERMINATION;

/**
 * Returns an autoreleased object that will selectively dispatch messages to the provided
 * objects as they are received. The order of the objects in the array determines
 * the order in which method lookup and dispatch occurs.
 *
 * @note All provided objects are retained until the returned object is deallocated.
 *
 * @warning Lookup will not work for wrapped objects that were in a collection
 * other than \a objects at the time of the multi-object's initialization.
 */
+ (id)multiObjectForObjectsInArray:(NSArray *)objects;

@end
