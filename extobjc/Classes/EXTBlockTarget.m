//
//  EXTBlockTarget.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-04-18.
//  Released into the public domain.
//

#import "EXTBlockTarget.h"
#import <objc/runtime.h>

// doesn't include 'self' and '_cmd'
static
size_t argumentCountForSelectorName (const char *name) {
	size_t nameLength = strlen(name);
	size_t argCount = 0;

	// assume that the very first character won't be a colon
	NSCAssert(name[0] != ':', @"expected method name to start with something other than a colon");

	// and start on the second
	for (size_t i = 1;i < nameLength;++i) {
		if (name[i] == ':')
			++argCount;
	}

	return argCount;
}

typedef void (^action0)(void);
typedef void (^action1)(id);
typedef void (^action2)(id, id);

@interface EXTBlockTarget ()
@property (nonatomic, assign) SEL name;
@property (nonatomic, copy) id implementation;
@end

@implementation EXTBlockTarget
@synthesize name;
@synthesize implementation;

+ (id)blockTargetFor:(id)control selector:(SEL)actionName action:(id)block {
	id target = [self blockTargetWithSelector:actionName action:block];
	objc_setAssociatedObject(control, actionName, target, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

	return target;
}

+ (id)blockTargetWithSelector:(SEL)actionName action:(id)block {
	return [[[self alloc] initWithSelector:actionName action:block] autorelease];
}

- (id)initWithSelector:(SEL)actionName action:(id)block {
	if ((self = [super init])) {
		self.name = actionName;
		self.implementation = block;
	}

	return self;
}

- (void)dealloc {
	self.implementation = nil;
	[super dealloc];
}

#pragma mark Forwarding machinery

- (void)forwardInvocation:(NSInvocation *)anInvocation {
	if ([anInvocation selector] != name) {
		[self doesNotRecognizeSelector:[anInvocation selector]];
		return;
	}

	NSUInteger numberOfArguments = [[anInvocation methodSignature] numberOfArguments];
	switch (numberOfArguments) {
	case 2:
		{
			action0 impl = (action0)self.implementation;
			impl();
		}
		
		break;

	case 3:
		{
			action1 impl = (action1)self.implementation;

			id sender = nil;
			[anInvocation getArgument:&sender atIndex:2];
			impl(sender);
		}
		
		break;

	case 4:
		{
			action2 impl = (action2)self.implementation;

			id sender = nil;
			[anInvocation getArgument:&sender atIndex:2];

			id event = nil;
			[anInvocation getArgument:&sender atIndex:3];

			impl(sender, event);
		}
		
		break;

	default:
		NSAssert(NO, @"EXTBlockTarget only supports actions with zero, one, or two arguments");
	}
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
	NSMethodSignature *signature = [super methodSignatureForSelector:aSelector];
	if (signature)
		return signature;
	
	size_t argCount = argumentCountForSelectorName(sel_getName(aSelector));
	const char *idType = @encode(id);
	const char *selType = @encode(SEL);
	NSString *typeString = nil;

	switch (argCount) {
	case 0:
		// (id self, SEL _cmd)
		typeString = [NSString stringWithFormat:@"%s%s", idType, selType];
		break;
		
	case 1:
		// (id self, SEL _cmd, id sender)
		typeString = [NSString stringWithFormat:@"%s%s%s", idType, selType, idType];
		break;

	case 2:
		// (id self, SEL _cmd, id sender, id event)
		typeString = [NSString stringWithFormat:@"%s%s%s%s", idType, selType, idType, idType];
		break;

	default:
		;
	}

	if (typeString) {
		signature = [NSMethodSignature signatureWithObjCTypes:[typeString UTF8String]];
	}

	return signature;
}

#pragma mark NSObject protocol

- (BOOL)respondsToSelector:(SEL)aSelector {
	if ([super respondsToSelector:aSelector])
		return YES;
	else
		return aSelector == self.name;
}

@end
