//
//  EXTPrototype.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-03-11.
//  Released into the public domain.
//

#import "EXTPrototype.h"
#import "EXTBlockMethod.h"
#import "EXTRuntimeExtensions.h"
#import <assert.h>
#import <ctype.h>

// doesn't include 'self' and '_cmd'
static
size_t argumentCountForSelectorName (const char *name) {
	size_t nameLength = strlen(name);
	size_t argCount = 0;

	// assume that the very first character won't be a colon
	assert(name[0] != ':');

	// and start on the second
	for (size_t i = 1;i < nameLength;++i) {
		if (name[i] == ':')
			++argCount;
	}

	return argCount;
}

static
BOOL nameIsSetter (const char *name) {
	return strncmp(name, "set", 3) == 0 && isupper(name[3]);
}

static
char *newTypeStringForArgumentCount (size_t argCount) {
	const char *idType = @encode(id);
	size_t idLen = strlen(idType);

	const char *selType = @encode(SEL);
	size_t selLen = strlen(selType);

	size_t typeStringLength = idLen + selLen + idLen * argCount;
	char *typeString = malloc(typeStringLength + 1);

	strncpy(typeString, idType, idLen);
	strncpy(typeString + idLen, selType, selLen);

	char *moving = typeString + idLen + selLen;
	for (size_t i = 0;i < argCount;++i) {
		strncpy(moving, idType, idLen);
		moving += idLen;
	}

	*moving = '\0';
	return typeString;
}

static
id *copyParents (CFDictionaryRef dict, size_t *outCount) {
	size_t totalParents = 0;

	CFIndex count = CFDictionaryGetCount(dict);
	const void *values[count];

	{
		const void *keys[count];

		CFDictionaryGetKeysAndValues(
			dict,
			keys,
			values
		);

		for (CFIndex i = 0;i < count;++i) {
			CFStringRef key = keys[i];
			if (CFStringHasPrefix(key, CFSTR("parent")))
				++totalParents;
			else
				values[i] = NULL;
		}
	}

	id *parents = malloc((totalParents + 1) * sizeof(id));
	
	// use this to keep track of how many we actually fill in (we may not fill
	// in some because they turn out to not actually be proto-objects)
	totalParents = 0;
	for (CFIndex i = 0;i < count;++i) {
		id value = values[i];
		if ([value isKindOfClass:[EXTPrototype class]])
			parents[totalParents++] = value;
	}

	// NULL-terminate
	parents[totalParents] = NULL;

	if (outCount)
		*outCount = totalParents;

	return parents;
}

@interface EXTPrototype ()
- (BOOL)respondToInvocationWithSlot:(NSInvocation *)anInvocation;
@end

@implementation EXTPrototype
// useful method signatures
+ (void)setSlot:(id)obj {}
+ (void)setSlot:(id)obj argumentCount:(int)count {}

#pragma mark Object lifecycle

+ (Class)uniqueClass {
	NSString *uniqueClassName = [[NSProcessInfo processInfo] globallyUniqueString];
	uniqueClassName = [@"EXTPrototypeStub_" stringByAppendingString:uniqueClassName];

	Class newClass = objc_allocateClassPair(
		self,
		[uniqueClassName UTF8String],
		0
	);

	if (!newClass) {
		return nil;
	}

	objc_registerClassPair(newClass);
	return newClass;
}

+ (id)prototype {
	EXTPrototype *obj = [[[self alloc] init] autorelease];

	obj->uniqueClass = [self uniqueClass];
	obj->slots = CFDictionaryCreateMutable(
		NULL,
		0,
		&kCFCopyStringDictionaryKeyCallBacks,
		&kCFTypeDictionaryValueCallBacks
	);

	return obj;
}

- (void)dealloc {
	if (slots) {
		CFRelease(slots);
		slots = NULL;
	}

	[super dealloc];
}

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone {
	EXTPrototype *obj = [[[self class] allocWithZone:zone] init];
	obj->uniqueClass = [EXTPrototype uniqueClass];
	obj->slots = CFDictionaryCreateMutableCopy(
		NULL,
		0,
		slots
	);

	return obj;
}

#pragma mark Forwarding machinery

- (void)forwardInvocation:(NSInvocation *)anInvocation {
	if (![self respondToInvocationWithSlot:anInvocation])
		[self doesNotRecognizeSelector:[anInvocation selector]];
}

- (BOOL)respondToInvocationWithSlot:(NSInvocation *)anInvocation {
	const char *name = sel_getName([anInvocation selector]);
	size_t argCount = argumentCountForSelectorName(name);

	Class blockClass = objc_getClass("NSBlock");

	// TODO: this should really check for method signatures here, not selector names
	BOOL isSetter = ((argCount == 1 || argCount == 2) && nameIsSetter(name));
	if (isSetter) {
		// we assume that the setter name contains a trailing colon
		assert(name[strlen(name) - 1] == ':');

		// don't include the trailing colon
		size_t slotLength = strlen(name + 3) - 1;

		CFStringRef slotKey = CFStringCreateWithBytes(
			NULL,
			(void *)(name + 3),
			slotLength,
			kCFStringEncodingUTF8,
			false
		);

		id slotValue = nil;
		[anInvocation getArgument:&slotValue atIndex:0];

		int slotArgumentCount = 0;
		if (argCount == 2)
			[anInvocation getArgument:&slotArgumentCount atIndex:1];

		id existingValue = (id)CFDictionaryGetValue(slots, slotKey);

		CFDictionaryReplaceValue(
			slots,
			slotKey,
			slotValue
		);
		
		if ([slotValue isKindOfClass:blockClass]) {
			char * restrict typeString = newTypeStringForArgumentCount(slotArgumentCount);

			// add the block as a method
			class_replaceMethod(
				uniqueClass,
				NSSelectorFromString((id)slotKey),
				ext_blockImplementation(slotValue),
				typeString
			);

			free(typeString);
		} else if ([existingValue isKindOfClass:blockClass]) {
			// remove the block as a method
			ext_removeMethod(uniqueClass, NSSelectorFromString((id)slotKey));
		}

		CFRelease(slotKey);
		return YES;
	}

	const char *firstArg = strchr(name, ':');
	size_t slotLength;
	
	if (firstArg) {
		slotLength = firstArg - name;
		assert(slotLength != 0);
	} else
		slotLength = strlen(name);

	CFStringRef slotKey = CFStringCreateWithBytes(
		NULL,
		(void *)name,
		slotLength,
		kCFStringEncodingUTF8,
		false
	);

	id slotValue = (id)CFDictionaryGetValue(slots, slotKey);
	CFRelease(slotKey);

	if ([slotValue isKindOfClass:blockClass]) {
		[anInvocation invokeWithTarget:uniqueClass];
		return YES;
	} else if (argCount == 0) {
		[anInvocation setReturnValue:&slotValue];
		return YES;
	}

	// try looking up in the parents of this prototype
	id *parents = copyParents(slots, NULL);
	BOOL success = NO;

	if (parents) {
		while (*parents != NULL) {
			if ([*parents respondToInvocationWithSlot:anInvocation]) {
				success = YES;
				break;
			}
		}

		free(parents);
	}

	return success;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
	NSMethodSignature *signature = [EXTPrototype instanceMethodSignatureForSelector:aSelector];
	if (signature)
		return signature;
	
	const char *name = sel_getName(aSelector);

	size_t argCount = argumentCountForSelectorName(name);
	if (nameIsSetter(name)) {
		if (argCount == 1) {
			return [EXTPrototype methodSignatureForSelector:@selector(setSlot:)];
		} else if (argCount == 2) {
			return [EXTPrototype methodSignatureForSelector:@selector(setSlot:argumentCount:)];
		}
	}

	char * restrict typeString = newTypeStringForArgumentCount(argCount);
	signature = [NSMethodSignature signatureWithObjCTypes:typeString];
	free(typeString);

	return signature;
}

#pragma mark NSObject protocol

- (NSUInteger)hash {
	return CFHash(slots);
}

- (BOOL)isEqual:(id)obj {
	if (![obj isKindOfClass:[EXTPrototype class]])
		return NO;

	EXTPrototype *proto = obj;
	return CFEqual(slots, proto->slots);
}

- (BOOL)respondsToSelector:(SEL)aSelector {
	return YES;
}
@end
