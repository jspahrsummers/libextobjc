//
//  EXTMultiObject.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 2010-11-09.
//  Released into the public domain.
//

#import "EXTMultiObject.h"

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

	id *targets = malloc(sizeof(id) * count);
	if (!targets) {
		va_end(argsCopy);
		return nil;
	}

	targets[0] = firstObj;
	for (NSUInteger i = 1;i < count;++i) {
		targets[i] = va_arg(argsCopy, id);
		NSAssert(targets[i] != nil, @"argument should not be nil after previously being non-nil");
	}

	va_end(argsCopy);

	EXTMultiObject *multiObj = [[[EXTMultiObject alloc] init] autorelease];
	multiObj->targets = targets;
	multiObj->targetCount = count;
	return multiObj;
}

+ (id)multiObjectForObjectsInArray:(NSArray *)objects {
	NSUInteger count = [objects count];
	if (!count)
		return nil;
	
	id *targets = malloc(sizeof(id) * count);
	[objects getObjects:targets range:NSMakeRange(0, count)];

	EXTMultiObject *multiObj = [[[EXTMultiObject alloc] init] autorelease];
	multiObj->targets = targets;
	multiObj->targetCount = count;
	return multiObj;
}

- (void)dealloc {
	for (NSUInteger i = 0;i < targetCount;++i) {
		[targets[i] release];
	}

	free(targets);
	targets = NULL;
	targetCount = 0;

	[super dealloc];
}

#pragma mark Forwarding machinery

- (id)forwardingTargetForSelector:(SEL)aSelector {
	for (NSUInteger i = 0;i < targetCount;++i) {
		if ([targets[i] respondsToSelector:aSelector])
			return targets[i];
	}

	return [super forwardingTargetForSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
	SEL selector = [anInvocation selector];
	for (NSUInteger i = 0;i < targetCount;++i) {
		if ([targets[i] respondsToSelector:selector]) {
			[anInvocation invokeWithTarget:targets[i]];
			return;
		}
	}

	[self doesNotRecognizeSelector:selector];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
	for (NSUInteger i = 0;i < targetCount;++i) {
		if ([targets[i] respondsToSelector:aSelector]) {
			return [targets[i] methodSignatureForSelector:aSelector];
		}
	}
	
	return [super methodSignatureForSelector:aSelector];
}

#pragma mark NSObject protocol

- (BOOL)conformsToProtocol:(Protocol *)aProtocol {
	for (NSUInteger i = 0;i < targetCount;++i) {
		if ([targets[i] conformsToProtocol:aProtocol])
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
	if (obj == self)
		return YES;
	
  	for (NSUInteger i = 0;i < targetCount;++i) {
		if ([targets[i] isEqual:obj])
			return YES;
	}

	return NO;
}

- (BOOL)isKindOfClass:(Class)cls {
  	for (NSUInteger i = 0;i < targetCount;++i) {
		if ([targets[i] isKindOfClass:cls])
			return YES;
	}

	return [super isKindOfClass:cls];
}

- (BOOL)isMemberOfClass:(Class)cls {
  	for (NSUInteger i = 0;i < targetCount;++i) {
		if ([targets[i] isMemberOfClass:cls])
			return YES;
	}

	return [super isMemberOfClass:cls];
}

- (BOOL)respondsToSelector:(SEL)aSelector {
	for (NSUInteger i = 0;i < targetCount;++i) {
		if ([targets[i] respondsToSelector:aSelector])
			return YES;
	}

	return [super respondsToSelector:aSelector];
}

@end
