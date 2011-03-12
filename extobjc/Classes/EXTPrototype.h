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
    CFMutableDictionaryRef slots;
	Class uniqueClass;
}

/**
 * Returns an empty prototype-object containing no slots.
 */
+ (id)prototype;

@end
