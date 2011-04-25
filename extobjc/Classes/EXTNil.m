//
//  EXTNil.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-04-25.
//  Released into the public domain.
//

#import "EXTNil.h"
#import "EXTRuntimeExtensions.h"

static id singleton = nil;

@implementation EXTNil
+ (void)initialize {
	if (self == [EXTNil class]) {
		if (!singleton)
			singleton = [[self alloc] init];
	}
}

+ (EXTNil *)null {
	return singleton;
}

#pragma mark Forwarding machinery

- (void)forwardInvocation:(NSInvocation *)anInvocation {
	NSUInteger returnLength = [[anInvocation methodSignature] methodReturnLength];

	// set return value to all zero bits
	char buffer[returnLength];
	memset(buffer, 0, returnLength);

	[anInvocation setReturnValue:buffer];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
	NSMethodSignature *signature = [super methodSignatureForSelector:aSelector];
	if (signature)
		return signature;

	return ext_globalMethodSignatureForSelector(aSelector);
}

#pragma mark NSObject protocol

- (BOOL)conformsToProtocol:(Protocol *)aProtocol {
	return NO;
}

- (NSUInteger)hash {
  	return 0;
}

- (BOOL)isEqual:(id)obj {
	if (obj == self)
		return YES;
	else
		return NO;
}

- (BOOL)isKindOfClass:(Class)cls {
	return [EXTNil isKindOfClass:cls];
}

- (BOOL)isMemberOfClass:(Class)cls {
	return [EXTNil isMemberOfClass:cls];
}
@end
