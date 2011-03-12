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
#import "NSMethodSignature+EXT.h"
#import <assert.h>
#import <ctype.h>

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

	                       // id (*)  (id,    SEL,     ...)
	size_t typeStringLength = idLen + idLen + selLen + idLen * argCount;
	char *typeString = malloc(typeStringLength + 1);

	strncpy(typeString, idType, idLen);
	strncpy(typeString + idLen, idType, idLen);
	strncpy(typeString + idLen * 2, selType, selLen);

	char *moving = typeString + idLen * 2 + selLen;
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

static
void invokeBlockMethodWithSelf (NSInvocation *invocation, id self) {
	NSMethodSignature *signature = [invocation methodSignature];

	NSLog(@"%s", __func__);
	NSLog(@"selector: %s", sel_getName([invocation selector]));
	NSLog(@"signature type: %s", [signature typeEncoding]);

	// add a faked 'id self' argument
	NSMethodSignature *newSignature = [signature methodSignatureByInsertingType:@encode(id) atArgumentIndex:2];
	NSInvocation *newInvocation = [NSInvocation invocationWithMethodSignature:newSignature];

	[newInvocation setTarget:[invocation target]];
	[newInvocation setSelector:[invocation selector]];
	[newInvocation setArgument:&self atIndex:2];

	NSUInteger origArgumentCount = [signature numberOfArguments];
	NSCAssert(origArgumentCount - 1 == [newSignature numberOfArguments], @"expected method signature and modified method signature to differ only in one argument");

	{
		char buffer[[signature frameLength]];
		for (NSUInteger i = 2;i < origArgumentCount;++i) {
			[invocation getArgument:buffer atIndex:i];
			[newInvocation setArgument:buffer atIndex:i + 1];
		}
	}

	[self retain];
	[newInvocation invoke];
	[self release];
	
	NSCAssert([signature methodReturnLength] == [newSignature methodReturnLength], @"expected method signature and modified method signature to have the same return type");

	char returnValue[[signature methodReturnLength]];
	[newInvocation getReturnValue:returnValue];
	[invocation setReturnValue:returnValue];
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
	NSLog(@"%s", __func__);
	NSLog(@"selector: %s", sel_getName([anInvocation selector]));
	NSLog(@"signature type: %s", [[anInvocation methodSignature] typeEncoding]);

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
		NSAssert(name[strlen(name) - 1] == ':', @"expected setter name to have a trailing colon");

		// don't include the trailing colon
		size_t slotLength = strlen(name + 3) - 1;
		CFStringRef slotKey = NULL;

		{
			char lowercaseSlot[slotLength];

			strncpy(lowercaseSlot, name + 3, slotLength);
			lowercaseSlot[0] = tolower(lowercaseSlot[0]);

			slotKey = CFStringCreateWithBytes(
				NULL,
				(void *)lowercaseSlot,
				slotLength,
				kCFStringEncodingUTF8,
				false
			);
		}

		NSLog(@"slotKey: %@", (id)slotKey);

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
			ext_replaceBlockMethod(
				uniqueClass,
				NSSelectorFromString((id)slotKey),
				slotValue,
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
		NSAssert(slotLength != 0, @"expected method name containing colon to also have an identifier");
	} else
		slotLength = strlen(name);

	CFStringRef slotKey = CFStringCreateWithBytes(
		NULL,
		(void *)name,
		slotLength,
		kCFStringEncodingUTF8,
		false
	);

	NSLog(@"slotKey: %@", (id)slotKey);

	id slotValue = (id)CFDictionaryGetValue(slots, slotKey);
	CFRelease(slotKey);

	NSLog(@"slotValue: %@", slotValue);
	NSLog(@"[slotValue class]: %@", [slotValue class]);

	if ([slotValue isKindOfClass:blockClass]) {
		[anInvocation setTarget:uniqueClass];

		invokeBlockMethodWithSelf(anInvocation, self);
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
	NSLog(@"%s", __func__);
	NSLog(@"selector: %s", sel_getName(aSelector));

	NSMethodSignature *signature = [EXTPrototype instanceMethodSignatureForSelector:aSelector];
	if (signature) {
		NSLog(@"signature type: %s", [signature typeEncoding]);
		NSLog(@"number of args: %lu", (unsigned long)[signature numberOfArguments]);
		return signature;
	}
	
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
	NSLog(@"typeString: %s", typeString);

	signature = [NSMethodSignature signatureWithObjCTypes:typeString];
	free(typeString);

	NSLog(@"signature type: %s", [signature typeEncoding]);
	NSLog(@"number of args: %lu", (unsigned long)[signature numberOfArguments]);

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
