//
//  EXTBlockMethod.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-03-11.
//  Released into the public domain.
//

#import "EXTBlockMethod.h"
#import "NSMethodSignature+EXT.h"
#import <libkern/OSAtomic.h>
#import <stdio.h>
#import <string.h>

#define originalForwardInvocationSelector \
	@selector(ext_originalForwardInvocation_:)

#define originalMethodSignatureForSelectorSelector \
	@selector(ext_originalMethodSignatureForSelector_:)

#define originalRespondsToSelectorSelector \
	@selector(ext_originalRespondsToSelector_:)

typedef NSMethodSignature *(*methodSignatureForSelectorIMP)(id, SEL, SEL);
typedef void (*forwardInvocationIMP)(id, SEL, NSInvocation *);
typedef BOOL (*respondsToSelectorIMP)(id, SEL, SEL);

static
id ext_blockWithSelector (Class cls, SEL aSelector) {
	return objc_getAssociatedObject(cls, aSelector);
}

static
void ext_installBlockWithSelector (Class cls, id block, SEL aSelector) {
	objc_setAssociatedObject(cls, aSelector, block, OBJC_ASSOCIATION_COPY);
}

static
void ext_invokeBlockMethodWithSelf (id block, NSInvocation *invocation, id self) {
	NSMethodSignature *signature = [invocation methodSignature];

	NSLog(@"%s", __func__);
	NSLog(@"selector: %s", sel_getName([invocation selector]));
	NSLog(@"signature type: %s", [signature typeEncoding]);

	// add a faked 'id self' argument
	NSMethodSignature *newSignature = [signature methodSignatureByInsertingType:@encode(id) atArgumentIndex:2];
	NSInvocation *newInvocation = [NSInvocation invocationWithMethodSignature:newSignature];

	NSLog(@"new signature type: %s", [newSignature typeEncoding]);

	[newInvocation setTarget:block];
	[newInvocation setSelector:[invocation selector]];
	[newInvocation setArgument:&self atIndex:2];

	NSUInteger origArgumentCount = [signature numberOfArguments];
	NSCAssert(origArgumentCount + 1 == [newSignature numberOfArguments], @"expected method signature and modified method signature to differ only in one argument");

	if (origArgumentCount > 2) {
		char buffer[[signature frameLength]];

		for (NSUInteger i = 2;i < origArgumentCount;++i) {
			NSLog(@"copying argument %lu", (unsigned long)i);
			[invocation getArgument:buffer atIndex:i];
			[newInvocation setArgument:buffer atIndex:i + 1];
		}
	}

	NSLog(@"about to invoke against %p (%@)", (void *)self, [self class]);
	[newInvocation invoke];
	
	NSCAssert([signature methodReturnLength] == [newSignature methodReturnLength], @"expected method signature and modified method signature to have the same return type");

	if ([signature methodReturnLength]) {
		char returnValue[[signature methodReturnLength]];
		[newInvocation getReturnValue:returnValue];
		[invocation setReturnValue:returnValue];
	}
}

static
NSMethodSignature *ext_blockMethodSignatureForSelector (id self, SEL _cmd, SEL aSelector) {
	Class cls = object_getClass(self);
	methodSignatureForSelectorIMP originalImpl = (methodSignatureForSelectorIMP)class_getMethodImplementation(cls, originalMethodSignatureForSelectorSelector);

	NSMethodSignature *signature = originalImpl(self, _cmd, aSelector);
	if (signature)
		return signature;

	id block = ext_blockWithSelector(cls, aSelector);
	if (!block) {
		fprintf(stderr, "ERROR: Could not find block method implementation of %s on class %s\n", sel_getName(aSelector), class_getName(cls));
		return nil;
	}

	Method blockMethod = class_getInstanceMethod(object_getClass(block), aSelector);
	if (!blockMethod) {
		fprintf(stderr, "ERROR: Could not get block method %s from itself\n", sel_getName(aSelector));
		return nil;
	}

	return [NSMethodSignature signatureWithObjCTypes:method_getTypeEncoding(blockMethod)];
}

static
void ext_blockForwardInvocation (id self, SEL _cmd, NSInvocation *invocation) {
	Class cls = object_getClass(self);
	SEL aSelector = [invocation selector];

	id block = ext_blockWithSelector(cls, aSelector);
	if (block) {
		// update invocation and call through to block
		ext_invokeBlockMethodWithSelf(block, invocation, self);
		return;
	}

	// otherwise, invoke original implementation of forwardInvocation: (if
	// there is one)
	Method superclassMethod = class_getInstanceMethod(self, originalForwardInvocationSelector);

	if (superclassMethod) {
		forwardInvocationIMP originalImpl = (forwardInvocationIMP)method_getImplementation(superclassMethod);
		originalImpl(self, _cmd, invocation);
	} else {
		[self doesNotRecognizeSelector:aSelector];
	}
}

static
BOOL ext_blockRespondsToSelector (id self, SEL _cmd, SEL aSelector) {
	Class cls = object_getClass(self);
	respondsToSelectorIMP originalImpl = (respondsToSelectorIMP)class_getMethodImplementation(cls, originalRespondsToSelectorSelector);

	if (originalImpl(self, _cmd, aSelector))
		return YES;

	id block = ext_blockWithSelector(cls, aSelector);
	return (block != nil);
}

static
void ext_installSpecialBlockMethods (Class aClass) {
	SEL selectorsToInject[] = {
		@selector(forwardInvocation:),
		@selector(methodSignatureForSelector:),
		@selector(respondsToSelector:)
	};

	IMP newImplementations[] = {
		(IMP)&ext_blockForwardInvocation,
		(IMP)&ext_blockMethodSignatureForSelector,
		(IMP)&ext_blockRespondsToSelector
	};

	SEL renamedSelectors[] = {
		originalForwardInvocationSelector,
		originalMethodSignatureForSelectorSelector,
		originalRespondsToSelectorSelector
	};

	size_t methodCount = sizeof(selectorsToInject) / sizeof(*selectorsToInject);
	for (size_t i = 0;i < methodCount;++i) {
		SEL name = selectorsToInject[i];

		Method originalMethod = class_getInstanceMethod(aClass, name);
		const char *type = method_getTypeEncoding(originalMethod);

		BOOL success = class_addMethod(
			aClass,
			renamedSelectors[i],
			method_getImplementation(originalMethod),
			type
		);

		if (!success) {
			// if this method couldn't be injected, we assume that the methods
			// we need have already been fully installed
			break;
		}

		class_replaceMethod(
			aClass,
			name,
			newImplementations[i],
			type
		);
	}
}

BOOL ext_addBlockMethod (Class aClass, SEL name, id block, const char *types) {
	if (ext_blockWithSelector(aClass, name))
		return NO;
	
	ext_installSpecialBlockMethods(aClass);

	class_replaceMethod(
		object_getClass(block),
		name,
		ext_blockImplementation(block),
		types
	);

	ext_installBlockWithSelector(aClass, block, name);
	return YES;
}

IMP ext_blockImplementation (id block) {
	IMP impl = NULL;

	// the function pointer for a block is at +12 bytes on iOS (32 bit) and +16
	// bytes on OS X (64 bit), so we assume a constant of +8 incremented by the
	// size of a pointer
	impl = *(IMP *)((char *)block + 8 + sizeof(void *));

	return impl;
}

void ext_replaceBlockMethod (Class aClass, SEL name, id block, const char *types) {
	ext_installSpecialBlockMethods(aClass);

	class_replaceMethod(
		object_getClass(block),
		name,
		ext_blockImplementation(block),
		types
	);

	ext_installBlockWithSelector(aClass, block, name);

	//Method existingMethod = 
}

void ext_synthesizeBlockProperty (ext_propertyMemoryManagementPolicy memoryManagementPolicy, BOOL atomic, ext_blockGetter *getter, ext_blockSetter *setter) {
	__block volatile id backingVar = nil;

	ext_blockGetter localGetter = nil;
	ext_blockSetter localSetter = nil;

	localGetter = ^{
		return [[backingVar retain] autorelease];
	};

	localSetter = ^(id newValue){
		switch (memoryManagementPolicy) {
		case ext_propertyMemoryManagementPolicyRetain:
			[newValue retain];
			break;

		case ext_propertyMemoryManagementPolicyCopy:
			newValue = [newValue copy];
			break;

		default:
			;
		}

		if (atomic) {
			for (;;) {
				id existingValue = backingVar;
				if (OSAtomicCompareAndSwapPtrBarrier(existingValue, newValue, (void * volatile *)&backingVar)) {
					if (memoryManagementPolicy != ext_propertyMemoryManagementPolicyAssign)
						[existingValue release];

					break;
				}
			}
		} else {
			if (memoryManagementPolicy != ext_propertyMemoryManagementPolicyAssign)
				[backingVar release];

			backingVar = newValue;
		}
	};

	*getter = [[localGetter copy] autorelease];
	*setter = [[localSetter copy] autorelease];
}

