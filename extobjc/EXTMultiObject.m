//
//  EXTMultiObject.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 2010-11-09.
//  Copyright (C) 2012 Justin Spahr-Summers.
//  Released under the MIT license.
//

#import "EXTMultiObject.h"

@interface EXTMultiObject () {
    __strong NSArray *targets;
}

@end

@implementation EXTMultiObject

#pragma mark Object lifecycle

// only constructors provided are autoreleased ones, so that there are no weird
// method lookup issues from providing a custom -init... method

+ (id)multiObjectForObjects:(id)firstObj, ... {
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
    EXTMultiObject *multiObj = [[EXTMultiObject alloc] init];

    multiObj->targets = [NSArray arrayWithObjects:targets count:count];
    free(targets);

    return multiObj;
}

+ (id)multiObjectForObjectsInArray:(NSArray *)objects {
    NSUInteger count = [objects count];
    if (!count)
        return nil;

    // initialize the object and fill in its ivars
    EXTMultiObject *multiObj = [[EXTMultiObject alloc] init];
    multiObj->targets = [objects copy];
    return multiObj;
}

#pragma mark Forwarding machinery

- (id)forwardingTargetForSelector:(SEL)aSelector {
    // find the first target that responds to the specified selector
    //
    // this is somewhat unsafe, since method signatures may differ for two
    // methods with the same selector, but the performance gain from the
    // optimized forwarding machinery is probably a worthwhile tradeoff
    for (id target in targets) {
        if ([target respondsToSelector:aSelector])
            return target;
    }

    return [super forwardingTargetForSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    // find the first target that responds to the specified selector AND returns
    // the same method signature for that selector
    SEL selector = [anInvocation selector];
    NSMethodSignature *signature = [anInvocation methodSignature];

    for (id target in targets) {
        if ([target respondsToSelector:selector] && [[targets methodSignatureForSelector:selector] isEqual:signature]) {
            [anInvocation invokeWithTarget:target];
            return;
        }
    }

    // none of the targets recognized the selector
    [self doesNotRecognizeSelector:selector];
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
