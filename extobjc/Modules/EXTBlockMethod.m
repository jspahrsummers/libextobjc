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

#define DEBUG_LOGGING 1

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
	objc_setAssociatedObject(cls, aSelector, block, OBJC_ASSOCIATION_RETAIN);
}

static
SEL ext_uniqueSelectorForClass (SEL aSelector, Class cls) {
	const char *className = class_getName(cls);
	size_t classLen = strlen(className);

	const char *selName = sel_getName(aSelector);
	size_t selLen = strlen(selName);

	// include underscore and terminating NUL
	char newName[classLen + 1 + selLen + 1];

	strncpy(newName, className, classLen);
	newName[classLen] = '_';

	strncpy(newName + classLen + 1, selName, selLen);
	newName[classLen + 1 + selLen] = '\0';

	return sel_registerName(newName);
}

static
void ext_invokeBlockMethodWithSelf (id block, NSInvocation *invocation, id self, Class matchingClass) {
	NSMethodSignature *signature = [invocation methodSignature];

	#if DEBUG_LOGGING
	NSLog(@"%s", __func__);
	NSLog(@"selector: %s", sel_getName([invocation selector]));
	NSLog(@"invocation: %@", invocation);
	NSLog(@"signature: %@", signature);
	NSLog(@"signature type: %s", [signature typeEncoding]);
	#endif

	// add a faked 'id self' argument
	NSMethodSignature *newSignature = [signature methodSignatureByInsertingType:@encode(id) atArgumentIndex:2];
	NSInvocation *newInvocation = [NSInvocation invocationWithMethodSignature:newSignature];

	#if DEBUG_LOGGING
	NSLog(@"new signature type: %s", [newSignature typeEncoding]);
	#endif

	[newInvocation setTarget:block];
		
	SEL blockName = ext_uniqueSelectorForClass([invocation selector], matchingClass);
	[newInvocation setSelector:blockName];
	[newInvocation setArgument:&self atIndex:2];

	NSUInteger origArgumentCount = [signature numberOfArguments];
	NSCAssert(origArgumentCount + 1 == [newSignature numberOfArguments], @"expected method signature and modified method signature to differ only in one argument");

	if (origArgumentCount > 2) {
		char buffer[[signature frameLength]];

		for (NSUInteger i = 2;i < origArgumentCount;++i) {
			#if DEBUG_LOGGING
			NSLog(@"copying argument %lu", (unsigned long)i);
			#endif

			[invocation getArgument:buffer atIndex:i];
			[newInvocation setArgument:buffer atIndex:i + 1];
		}
	}

	#if DEBUG_LOGGING
	NSLog(@"about to invoke against %p (%@)", (void *)self, [self class]);
	#endif

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

	id block = nil;

	// traverse the class hierarchy
	do {
		block = ext_blockWithSelector(cls, aSelector);
		if (block)
			break;

		cls = class_getSuperclass(cls);
	} while (cls != nil);

	if (!block) {
		fprintf(stderr, "ERROR: Could not find block method implementation of %s on class %s\n", sel_getName(aSelector), class_getName(object_getClass(self)));
		return nil;
	}

	SEL name = ext_uniqueSelectorForClass(aSelector, cls);
	Method blockMethod = class_getInstanceMethod(object_getClass(block), name);
	if (!blockMethod) {
		fprintf(stderr, "ERROR: Could not get block method %s from itself\n", sel_getName(aSelector));
		return nil;
	}

	return [NSMethodSignature signatureWithObjCTypes:method_getTypeEncoding(blockMethod)];
}

static
void ext_blockForwardInvocation (id self, SEL _cmd, NSInvocation *invocation) {
	SEL aSelector = [invocation selector];

	#if DEBUG_LOGGING
	NSLog(@"self: %p", (void *)self);
	NSLog(@"_cmd: %@", NSStringFromSelector(_cmd));
	NSLog(@"selector: %@", NSStringFromSelector(aSelector));
	NSLog(@"invocation: %@", invocation);
	#endif

	Class cls = object_getClass(self);
	id block = nil;

	// traverse the class hierarchy
	do {
		#if DEBUG_LOGGING
		NSLog(@"cls: %@", cls);
		#endif

		block = ext_blockWithSelector(cls, aSelector);
		if (block) {
			// update invocation and call through to block
			ext_invokeBlockMethodWithSelf(block, invocation, self, cls);
			return;
		}

		cls = class_getSuperclass(cls);
	} while (cls != nil);

	// otherwise, invoke original implementation of forwardInvocation: (if
	// there is one)
	Method originalMethod = class_getInstanceMethod(self, originalForwardInvocationSelector);

	if (originalMethod) {
		forwardInvocationIMP originalImpl = (forwardInvocationIMP)method_getImplementation(originalMethod);
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

	id block = nil;

	// traverse the class hierarchy
	do {
		id block = ext_blockWithSelector(cls, aSelector);
		if (block)
			break;

		cls = class_getSuperclass(cls);
	} while (cls != nil);

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

		IMP originalImpl = method_getImplementation(originalMethod);
		if (originalImpl == newImplementations[i]) {
			// if the implementation of this method matches the one we want to
			// install, the methods we need have already been fully installed
			break;
		}

		const char *type = method_getTypeEncoding(originalMethod);

		BOOL success = class_addMethod(
			aClass,
			renamedSelectors[i],
			originalImpl,
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

	id copiedBlock = Block_copy(block);

	class_replaceMethod(
		object_getClass(copiedBlock),
		ext_uniqueSelectorForClass(name, aClass),
		ext_blockImplementation(copiedBlock),
		types
	);

	ext_installBlockWithSelector(aClass, copiedBlock, name);
	Block_release(copiedBlock);

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

	id copiedBlock = Block_copy(block);

	class_replaceMethod(
		object_getClass(copiedBlock),
		ext_uniqueSelectorForClass(name, aClass),
		ext_blockImplementation(copiedBlock),
		types
	);

	ext_installBlockWithSelector(aClass, copiedBlock, name);
	Block_release(copiedBlock);

	// find a method that we know not to exist, and get an
	// IMP internal to the runtime for message forwarding
	SEL forwardSelector = @selector(iouawhjfiue::::ajoijw:aF:);
	IMP forward = class_getMethodImplementation(aClass, forwardSelector);

	class_replaceMethod(
		aClass,
		name,
		forward,
		types
	);
}

void ext_synthesizeBlockProperty (ext_propertyMemoryManagementPolicy memoryManagementPolicy, BOOL atomic, ext_blockGetter *getter, ext_blockSetter *setter) {
	__block volatile id backingVar = nil;

	ext_blockGetter localGetter = nil;
	ext_blockSetter localSetter = nil;

	localGetter = blockMethod(id self){
		return [[backingVar retain] autorelease];
	};

	localSetter = blockMethod(id self, id newValue){
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

