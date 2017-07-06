//
//  EXTBlockTarget.h
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-04-18.
//  Copyright (C) 2012 Justin Spahr-Summers.
//  Released under the MIT license.
//

#import <Foundation/Foundation.h>

/**
 * A target that has one action implemented with a block. This is meant to
 * replace the use of selectors with Cocoa's target-action mechanism, but can
 * also be used with other, similar interfaces.
 *
 * This object should be created as needed to implement actions for those
 * interfaces which use a target-action mechanism, such as \c NSControl or \c
 * UIControl. Because targets are not retained, however, instances of this class
 * must be separately retained for the lifetime of the eventing object. The
 * easiest way to do this is through the associated objects facility:
 *
 * @code

id target = [EXTBlockTarget blockTargetWithSelector:@selector(tapped) action:^{ NSLog(@"button tapped!"); }];
[control addTarget:target action:@selector(tapped) forControlEvents:UIControlEventTouchUpInside];

objc_setAssociatedObject(control, @selector(tapped), target, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

 * @endcode
 *
 * The #blockTargetFor:selector:action: initializer provides a convenience
 * implementation of the above behavior.
 *
 * This class can also be used with other interfaces that expect a target and
 * a selector taking zero or one object arguments, like \c performSelector:
 * variants (though only those that do not use a return value).
 *
 * @code

id target = [EXTBlockTarget blockTargetWithSelector:@selector(afterOne) action:^{ NSLog(@"One second has passed"); }];
[target performSelector:@selector(afterOne) withObject:nil afterDelay:1];

 * @endcode
 */
@interface EXTBlockTarget : NSObject {
}

/**
 * Returns an autoreleased target initialized with #initWithSelector:action:.
 */
+ (id)blockTargetWithSelector:(SEL)actionName action:(id)block;

/**
 * Initializes a target with #initWithSelector:action: and then ties the
 * lifecycle of the resultant object to that of \a control by using associated
 * objects.
 *
 * The returned object will be retained as long as \a control is still alive.
 *
 * @code

[control
    addTarget:[EXTBlockTarget blockTargetFor:control selector:@selector(tapped) action:^{ NSLog(@"button tapped!"); }]
    action:@selector(tapped)
    forControlEvents:UIControlEventTouchUpInside
];

 * @endcode
 */
+ (id)blockTargetFor:(id)control selector:(SEL)actionName action:(id)block;

/**
 * Initializes this target object to implement \a actionName using \a block. \a
 * block must not return any value, and must only take zero, one, or two
 * arguments of object type. \a actionName must match \a block in the number of
 * arguments.
 */
- (id)initWithSelector:(SEL)actionName action:(id)block;

@end
