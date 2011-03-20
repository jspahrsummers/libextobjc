//
//  EXTBlockMethod.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-03-11.
//  Released into the public domain.
//

#import "EXTBlockMethod.h"
#import <libkern/OSAtomic.h>
#import <stdio.h>

static
id ext_blockWithSelector (Class cls, SEL aSelector) {
	while (cls != Nil) {
		id block = objc_getAssociatedObject(cls, aSelector);
		if (block)
			return block;

		cls = class_getSuperclass(cls);
	}

	return nil;
}

typedef NSMethodSignature *(*methodSignatureForSelectorIMP)(id, SEL, SEL);
typedef void (*forwardInvocationIMP)(id, SEL, NSInvocation *);
typedef BOOL (*respondsToSelectorIMP)(id, SEL, SEL);

static
NSMethodSignature *ext_blockMethodSignatureForSelector (id self, SEL _cmd, SEL aSelector) {
	Class cls = object_getClass(self);
	Class superclass = class_getSuperclass(cls);
	methodSignatureForSelectorIMP superclassImpl = (methodSignatureForSelectorIMP)class_getMethodImplementation(superclass, _cmd);

	if (superclassImpl == &ext_blockMethodSignatureForSelector) {
		fprintf(stderr, "Warning: Superclass %s implementation of %s is the same as that of %s\n", class_getName(superclass), sel_getName(_cmd), class_getName(cls));
	} else {
		NSMethodSignature *signature = superclassImpl(self, _cmd, aSelector);
		if (signature)
			return signature;
	}

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
		return;
	}

	// otherwise, invoke superclass implementation of forwardInvocation: (if
	// there is one)
	Class superclass = class_getSuperclass(cls);
	Method superclassMethod = class_getInstanceMethod(superclass, _cmd);

	if (superclassMethod) {
		forwardInvocationIMP superclassImpl = (forwardInvocationIMP)method_getImplementation(superclassMethod);
		superclassImpl(self, _cmd, invocation);
	} else {
		[self doesNotRecognizeSelector:_cmd];
	}
}

static
BOOL ext_blockRespondsToSelector (id self, SEL _cmd, SEL aSelector) {
	Class cls = object_getClass(self);
	Class superclass = class_getSuperclass(cls);
	respondsToSelectorIMP superclassImpl = (respondsToSelectorIMP)class_getMethodImplementation(superclass, _cmd);

	if (superclassImpl == &ext_blockRespondsToSelector) {
		fprintf(stderr, "Warning: Superclass %s implementation of %s is the same as that of %s\n", class_getName(superclass), sel_getName(_cmd), class_getName(cls));
	} else {
		if (superclassImpl(self, _cmd, aSelector))
			return YES;
	}

	id block = ext_blockWithSelector(cls, aSelector);
	return (block != nil);
}

BOOL ext_addBlockMethod (Class aClass, SEL name, id block, const char *types) {
	return class_addMethod(
		aClass,
		name,
		ext_blockImplementation(block),
		types
	);
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
	class_replaceMethod(
		aClass,
		name,
		ext_blockImplementation(block),
		types
	);
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

