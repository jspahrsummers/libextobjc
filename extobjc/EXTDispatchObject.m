//
//  EXTDispatchObject.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-03-11.
//  Copyright (C) 2012 Justin Spahr-Summers.
//  Released under the MIT license.
//

#import "EXTDispatchObject.h"

@interface EXTDispatchObject() {
    __strong NSArray *targets;
}

@end

@implementation EXTDispatchObject

#pragma mark Object lifecycle

// only constructors provided are autoreleased ones, so that there are no weird
// method lookup issues from providing a custom -init... method

+ (id)dispatchObjectForObjects:(id)firstObj, ... {
    if (!firstObj)
        return nil;

    va_list args, argsCopy;
    va_start(args, firstObj);
    va_copy(argsCopy, args);

    // loop through the arguments once and count how many there are
    NSUInteger count = 1;
    for (;;) {
        id obj = va_arg(args, id);
        if (!obj)
            break;

        ++count;
    }

    va_end(args);

    NSAssert(count >= 1, @"should be at least one object");

    // allocate an array of object pointers large enough for all of the
    // arguments
    __unsafe_unretained id *targets = (__unsafe_unretained id *)malloc(sizeof(id) * count);
    if (!targets) {
        va_end(argsCopy);
        return nil;
    }

    targets[0] = firstObj;
    for (NSUInteger i = 1;i < count;++i) {
        id obj = va_arg(argsCopy, id);
        targets[i] = obj;

        NSAssert(targets[i] != nil, @"argument should not be nil after previously being non-nil");
    }

    va_end(argsCopy);

    // then initialize the actual object and fill in its ivars
    EXTDispatchObject *obj = [[EXTDispatchObject alloc] init];

    obj->targets = [NSArray arrayWithObjects:targets count:count];
    free(targets);
    
    return obj;
}

+ (id)dispatchObjectForObjectsInArray:(NSArray *)objects {
    NSUInteger count = [objects count];
    if (!count)
        return nil;

    // initialize the object and fill in its ivars
    EXTDispatchObject *obj = [[EXTDispatchObject alloc] init];
    obj->targets = [objects copy];
    return obj;
}

#pragma mark Forwarding machinery

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    SEL selector = [anInvocation selector];
    NSMethodSignature *signature = [anInvocation methodSignature];

    BOOL recognized = NO;

    // find all targets that respond to the specified selector AND return
    // the same method signature for that selector
    for (id target in targets) {
        if ([target respondsToSelector:selector] && [[target methodSignatureForSelector:selector] isEqual:signature]) {
            [anInvocation invokeWithTarget:target];

            recognized = YES;
        }
    }

    if (!recognized) {
        // none of the targets recognized the selector
        [self doesNotRecognizeSelector:selector];
    }
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    // find the first target that responds to the specified selector
    for (id target in targets) {
        if ([target respondsToSelector:aSelector]) {
            return [target methodSignatureForSelector:aSelector];
        }
    }
    
    return [super methodSignatureForSelector:aSelector];
}

#pragma mark NSObject protocol

- (BOOL)conformsToProtocol:(Protocol *)aProtocol {
    // return YES if any targets conform to the specified protocol
    for (id target in targets) {
        if ([target conformsToProtocol:aProtocol])
            return YES;
    }

    return [super conformsToProtocol:aProtocol];
}

- (NSUInteger)hash {
    // sucky! but no usable hash is possible, since each object might compare
    // equal to different things in different ways
    return 0;
}

- (BOOL)isEqual:(id)obj {
    // short-circuit isEqual: for identity
    if (obj == self)
        return YES;
    
    // then fall back to a more expensive check – return YES if any one of the
    // targets are equal to the argument
    for (id target in targets) {
        if ([target isEqual:obj])
            return YES;
    }

    return NO;
}

- (BOOL)isKindOfClass:(Class)cls {
    // return YES if any targets are a kind of the argument
    for (id target in targets) {
        if ([target isKindOfClass:cls])
            return YES;
    }

    return [super isKindOfClass:cls];
}

- (BOOL)isMemberOfClass:(Class)cls {
    // return YES if any targets are a member of the argument
    for (id target in targets) {
        if ([target isMemberOfClass:cls])
            return YES;
    }

    return [super isMemberOfClass:cls];
}

- (BOOL)isProxy {
    return YES;
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    // return YES if any targets respond to the specified selector
    for (id target in targets) {
        if ([target respondsToSelector:aSelector])
            return YES;
    }

    return [super respondsToSelector:aSelector];
}
@end
