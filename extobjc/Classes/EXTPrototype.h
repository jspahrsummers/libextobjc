//
//  EXTPrototype.h
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-03-11.
//  Released into the public domain.
//

#import <Foundation/Foundation.h>
#import "EXTRuntimeExtensions.h"

/**
 * Declares a slot \a NAME for use with prototypes. This macro only provides
 * static typing information to the compiler -- its usage is not required. This
 * macro should be used at file scope, outside of any \c @interface or \c
 * @protocol declarations.
 */
#define slot(NAME) \
	interface EXTPrototype (EXTSlot_ ## NAME) \
	@property (nonatomic, retain) id NAME; \
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
 * prototypes and objects created from prototypes, as in the Self programming
 * language, which makes no distinction between the two.
 *
 * An EXTPrototype object is composed of slots. A slot is identified by its
 * name, and its value can be any object, similar to a dictionary. Slots can be
 * accessed using normal property dot syntax (though use of the #slot macro may
 * be necessary to suppress compiler warnings), or through methods such as
 * #setValue:forSlot: and #valueForSlot:. Assigning an object to a slot retains
 * it and allows it to later be read from that same slot.
 *
 * Blocks have slightly different behavior in a slot. When inserted into one,
 * a block replaces the default behavior of the slot, to instead invoke the
 * block every time the slot is accessed. This is how methods on a proto-object
 * are implemented. All such blocks should be defined using the #blockMethod
 * macro and should take at least one \c id argument (and zero arguments of any
 * non-object types); when called, the first \c id argument represents the
 * EXTPrototype upon which the block was invoked.
 *
 * If a block in a slot takes multiple arguments, it must be inserted into the
 * slot using #setBlock:forSlot:argumentCount:. Once set, the slot can be invoked
 * directly. If using the #slot macro to avoid compiler warnings, additional
 * arguments can be passed using \c withObject: as follows:
 *
 * @code

// to eliminate compiler complaints here, the following should be declared at file
// scope somewhere:
//
// @slot(string)
// @slot(appendString)
// @slot(replaceOccurrencesOfString)

EXTPrototype *obj = [EXTPrototype prototype];
obj.string = @"";

[obj setBlock:blockMethod(EXTPrototype *self, NSString *append){
	self.string = [self.string stringByAppendingString:append];
} forSlot:@"appendString" argumentCount:2];

[obj setBlock:blockMethod(EXTPrototype *self, NSString *search, NSString *replace){
	self.string = [self.string stringByReplacingOccurrencesOfString:search withString:replace];
} forSlot:@"replaceOccurrencesOfString" argumentCount:3];

[obj appendString:@"foobar"];
[obj replaceOccurrencesOfString:@"foo" withObject:@"bar"];

// this is also legal, though will cause compiler warnings
[obj replaceOccurrencesOfString:@"bar" withString:@"foo"];

 * @endcode
 *
 * Delegation or inheritance is possible through specially-designated parent
 * slots. A parent slot is identified as such by starting with the word "parent"
 * and by containing a reference to another EXTPrototype object. When looking
 * for the value of a slot (either for a getter or to invoke a method), if
 * unable to find the exact slot on the receiver, all parent slots will be
 * depth-first traversed in alphabetical order; for example, slot \c parentA and
 * all of its parents will be searched before slot \c parentB and all of its
 * parents.
 */
@interface EXTPrototype : NSObject <NSCopying> {
}

/**
 * Convenience declaration for using proto-object parents. Note that
 * proto-objects are not limited to one parent, nor is the use of a slot
 * named exactly "parent" required. See the class description for more
 * information.
 */
@property (nonatomic, retain) EXTPrototype *parent;

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
 *
 * @note \a slotName should not include the colons that will be added to the
 * method name.
 */
- (void)setBlock:(id)block forSlot:(NSString *)slotName argumentCount:(NSUInteger)argCount;

/**
 * Associates \a value with \a slotName. If \a value is a block, it is assumed
 * to take a single \c self argument. \a value may be \c nil to remove any value
 * currently associated with \a slotName.
 */
- (void)setValue:(id)value forSlot:(NSString *)slotName;

/**
 * Synthesizes a property \a slotName by creating a getter and a setter
 * according to the specified behavior. \a policy determines the retention
 * policy for any objects passed into the setter. Slots are always atomic.
 *
 * This can be called multiple times for the same slot. Each subsequent
 * invocation will overwrite the synthesis of the previous.
 *
 * @note If \a policy is #ext_propertyMemoryManagementPolicyRetain, the behavior
 * is no different from how slots normally work, except that explicit blocks are
 * created to function as the getter and setter.
 */
- (void)synthesizeSlot:(NSString *)slotName withMemoryManagementPolicy:(ext_propertyMemoryManagementPolicy)policy;

/**
 * Returns the value associated with \a slotName, or \c nil if there is no value
 * in the specified slot. If the value in the specified slot is a block, this
 * method will \e not invoke it.
 *
 * @note This does not search parents for \a slotName.
 */
- (id)valueForSlot:(NSString *)slotName;

@end
