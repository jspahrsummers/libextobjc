//
//  EXTPrototype.h
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-03-11.
//  Released into the public domain.
//

#import <Foundation/Foundation.h>

/**
 * Declares a slot \a NAME for use with prototypes. This macro only provides
 * static typing information to the compiler -- its usage is not required. This
 * macro should be used at file scope, outside of any \c @interface or \c
 * @protocol declarations.
 */
#define slot(NAME) \
	interface EXTPrototype (EXTSlot_ ## NAME) \
	@property (nonatomic, copy) id NAME; \
	\
	- (id)NAME:(id)arg1; \
	- (id)NAME:(id)arg1 withObject:(id)arg2; \
	- (id)NAME:(id)arg1 withObject:(id)arg2 withObject:(id)arg3; \
	- (id)NAME:(id)arg1 withObject:(id)arg2 withObject:(id)arg3 withObject:(id)arg4; \
	- (id)NAME:(id)arg1 withObject:(id)arg2 withObject:(id)arg3 withObject:(id)arg4 withObject:(id)arg5; \
	- (id)NAME:(id)arg1 withObject:(id)arg2 withObject:(id)arg3 withObject:(id)arg4 withObject:(id)arg5 withObject:(id)arg6; \
	@end

/**
 * Prototype-oriented programming for Cocoa. This class implements both
 * prototypes and objects created from prototypes in the style of Self (where
 * there is no distinction between the two).
 */
@interface EXTPrototype : NSObject <NSCopying> {
}

/**
 * Returns an empty prototype-object containing no slots.
 */
+ (id)prototype;

/**
 * Initializes an empty object with no slots.
 */
- (id)init;

/**
 * Invokes the implementation of \a slotName using the arguments of \a
 * invocation. The return value, if applicable, is placed back into \a
 * invocation upon completion. The method signature and arguments of \a
 * invocation should start \e after the automatic \c self parameter.
 *
 * @note This does not search parents for \a slotName.
 */
- (void)invokeSlot:(NSString *)slotName withInvocation:(NSInvocation *)invocation;

/**
 * Defines \a block to be the implementation for \a slotName. The number of
 * arguments taken by the block must be specified in \a argCount, and must be at
 * least one for normal block invocations to be successful. The block is assumed
 * to take a \c self argument for its first parameter.
 */
- (void)setBlock:(id)block forSlot:(NSString *)slotName argumentCount:(NSUInteger)argCount;

/**
 * Associates \a value with \a slotName. If \a value is a block, it is assumed
 * to take a single \c self argument. \a value may be \c nil to remove any value
 * currently associated with \a slotName.
 */
- (void)setValue:(id)value forSlot:(NSString *)slotName;

/**
 * Returns the value associated with \a slotName, or \c nil if there is no value
 * in the specified slot. If the value in the specified slot is a block, this
 * method will \e not invoke it.
 *
 * @note This does not search parents for \a slotName.
 */
- (id)valueForSlot:(NSString *)slotName;

@end
