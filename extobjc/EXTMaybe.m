//
//  EXTMaybe.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 21.01.12.
//  Copyright (C) 2012 Justin Spahr-Summers.
//  Released under the MIT license.
//

#import "EXTMaybe.h"
#import "EXTNil.h"
#import <objc/runtime.h>

@interface EXTMaybe () {
    /**
     * The error with which this object was instantiated.
     */
    NSError *m_error;
}

@end

@implementation EXTMaybe

#pragma mark Lifecycle

+ (id)maybeWithError:(NSError *)error; {
    // NSProxy does not implement -init
    EXTMaybe *maybe = [EXTMaybe alloc];
    maybe->m_error = error;

    return maybe;
}

#pragma mark Unwrapping

+ (id)validObjectWithMaybe:(id)maybe orElse:(id (^)(NSError *))block; {
    BOOL isError = [maybe isKindOfClass:[NSError class]];
    BOOL invalid = isError || !maybe || [maybe isEqual:[NSNull null]];

    if (!invalid)
        return maybe;

    if (!block)
        return nil;

    if ([object_getClass(maybe) isEqual:[EXTMaybe class]]) {
        EXTMaybe *maybeObj = maybe;
        maybe = maybeObj->m_error;
    }

    return block(isError ? maybe : nil);
}

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

#pragma mark Forwarding machinery

- (void)forwardInvocation:(NSInvocation *)invocation {
    SEL selector = invocation.selector;

    if ([m_error respondsToSelector:selector])
        [invocation invokeWithTarget:m_error];
    else
        [invocation invokeWithTarget:[EXTNil null]];
}

- (id)forwardingTargetForSelector:(SEL)selector {
    if ([m_error respondsToSelector:selector])
        return m_error;
    else
        return [EXTNil null];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector {
    return [m_error methodSignatureForSelector:selector] ?: [[EXTNil null] methodSignatureForSelector:selector];
}

- (BOOL)respondsToSelector:(SEL)selector {
    return [m_error respondsToSelector:selector] || [[EXTNil null] respondsToSelector:selector];
}

#pragma mark NSObject protocol

- (Class)class {
    if (m_error)
        return [m_error class];
    else
        return [EXTNil class];
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol {
    return [m_error conformsToProtocol:aProtocol] || [[EXTNil null] conformsToProtocol:aProtocol];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<EXTMaybe: %p error: %@>", (__bridge void *)self, m_error];
}

- (NSUInteger)hash {
    return [m_error hash] ?: [[EXTNil null] hash];
}

- (BOOL)isEqual:(id)obj {
    return [m_error isEqual:obj] || [[EXTNil null] isEqual:obj];
}

- (BOOL)isKindOfClass:(Class)class {
    return [m_error isKindOfClass:class] || [[EXTNil null] isKindOfClass:class];
}

- (BOOL)isMemberOfClass:(Class)class {
    return [m_error isMemberOfClass:class] || [[EXTNil null] isMemberOfClass:class];
}

- (Class)superclass {
    if (m_error)
        return [m_error superclass];
    else
        return [EXTNil superclass];
}

@end
