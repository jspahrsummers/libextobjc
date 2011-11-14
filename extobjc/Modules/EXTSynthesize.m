//
//  EXTSynthesize.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-05-12.
//  Released into the public domain.
//

#import "EXTSynthesize.h"
#import "EXTBlockMethod.h"
#import <libkern/OSAtomic.h>

#define DEBUG_LOGGING 1

typedef struct { int i; } *empty_struct_ptr_t;
typedef union { int i; } *empty_union_ptr_t;

typedef size_t (*indexedIvarSizeIMP)(id, SEL);

static void * const kIndexedIvarSizeKey = "IndexedIvarSize";

static
id ext_allocWithZonePlusIndexedIvars (id self, SEL _cmd, NSZone *zone) {
	NSUInteger indexedIvarSize = 0;

	Class cls = self;
	while (cls) {
		NSNumber *num = objc_getAssociatedObject(cls, kIndexedIvarSizeKey);
		NSUInteger numValue = [num unsignedIntegerValue];
		
		if (numValue) {
			// keep each class' ivars aligned at 32 bytes for safety
			if ((indexedIvarSize & 0x1F) != 0) {
				// round up to a multiple of 32
				indexedIvarSize = (indexedIvarSize & 0x1F) + 0x20;
			}

			indexedIvarSize += numValue;
		}

		cls = class_getSuperclass(cls);
	}

	return class_createInstance(
		self,
		indexedIvarSize
	);
}

static
void ext_synthesizePropertyAtIndexedOffset (Class cls, const ext_propertyAttributes * restrict attribs, size_t offset, ext_blockGetter * restrict getter, ext_blockSetter * restrict setter);

void ext_synthesizePropertiesForClass (Class cls) {
	unsigned count = 0;
	objc_property_t *properties = class_copyPropertyList(cls, &count);

	#if DEBUG_LOGGING
	NSLog(@"Property count for class %s: %u", class_getName(cls), count);
	#endif

	for (unsigned i = 0;i < count;++i) {
		#if DEBUG_LOGGING
		NSLog(@"Considering property %s, attributes %s", property_getName(properties[i]), property_getAttributes(properties[i]));
		#endif

		ext_propertyAttributes *attribs = ext_copyPropertyAttributes(properties[i]);
		ext_synthesizeProperty(cls, attribs);
		free(attribs);
	}

	free(properties);
}

void ext_synthesizeProperty (Class cls, const ext_propertyAttributes * restrict attribs) {
	static const char * const idType = @encode(id);
	static const char * const selType = @encode(SEL);
	static const char * const voidType = @encode(void);

	const size_t idLen = strlen(idType);
	const size_t selLen = strlen(selType);
	const size_t idSelLen = idLen + selLen;
	const size_t voidLen = strlen(voidType);

	#if DEBUG_LOGGING
	NSLog(@"About to synthesize property for %s", attribs->ivar);
	#endif

	if (!attribs->dynamic) {
		BOOL foundGetter = NO;
		BOOL foundSetter = NO;

		unsigned methodCount = 0;
		Method *methods = class_copyMethodList(cls, &methodCount);

		for (unsigned methodIndex = 0;methodIndex < methodCount;++methodIndex) {
			SEL methodName = method_getName(methods[methodIndex]);

			if (methodName == attribs->getter) {
				foundGetter = YES;
				break;
			} else if (methodName == attribs->setter) {
				foundSetter = YES;
				break;
			}
		}

		free(methods);

		#if DEBUG_LOGGING
		NSLog(@"foundGetter: %i", (int)foundGetter);
		NSLog(@"foundSetter: %i", (int)foundSetter);
		#endif

		// if no getter exists, or a setter should exist but does not, we
		// should synthesize something
		if (!foundGetter || (!foundSetter && !attribs->readonly)) {
			ext_blockGetter getter = nil;
			ext_blockSetter setter = nil;

			// TODO: use an existing Ivar if possible

			NSUInteger ivarSize = 0;
			NSUInteger ivarAlign = 0;
			NSGetSizeAndAlignment(attribs->type, &ivarSize, &ivarAlign);

			size_t offset = ext_addIndexedIvar(cls, ivarSize, ivarAlign);
			ext_synthesizePropertyAtIndexedOffset(cls, attribs, offset, &getter, &setter);

			#if DEBUG_LOGGING
			NSLog(@"New getter: %p", (void *)getter);
			NSLog(@"New setter: %p", (void *)setter);
			#endif

			size_t typeLen = strlen(attribs->type);

			if (!foundGetter && getter) {
				// generate the type encoding for this method
				char getterType[typeLen + idSelLen + 1];
				strncpy(getterType, attribs->type, typeLen);
				strncpy(getterType + typeLen, idType, idLen);
				strncpy(getterType + typeLen + idLen, selType, selLen);
				getterType[typeLen + idSelLen] = '\0';

				// install our synthesized getter
				if (!ext_addBlockMethod(cls, attribs->getter, getter, getterType))
					NSLog(@"Error installing synthesized getter %s on %@", sel_getName(attribs->getter), cls);
			}

			if (!foundSetter && setter) {
				// generate the type encoding for this method
				char setterType[voidLen + idSelLen + typeLen + 1];
				strncpy(setterType, voidType, voidLen);
				strncpy(setterType + voidLen, idType, idLen);
				strncpy(setterType + voidLen + idLen, selType, selLen);
				strncpy(setterType + voidLen + idSelLen, attribs->type, typeLen);
				setterType[voidLen + idSelLen + typeLen] = '\0';

				// install our synthesized setter
				if (!ext_addBlockMethod(cls, attribs->setter, setter, setterType))
					NSLog(@"Error installing synthesized setter %s on %@", sel_getName(attribs->setter), cls);
			}
		}
	}
}

static
void ext_synthesizePropertyAtIndexedOffset (Class cls, const ext_propertyAttributes * restrict attribs, size_t offset, ext_blockGetter * restrict getter, ext_blockSetter * restrict setter) {
	const char * restrict type = attribs->type;
	ext_propertyMemoryManagementPolicy memoryManagementPolicy = attribs->memoryManagementPolicy;
	BOOL atomic = !attribs->nonatomic;

	// skip attributes in the provided type encoding
	while (
		*type == 'r' ||
		*type == 'n' ||
		*type == 'N' ||
		*type == 'o' ||
		*type == 'O' ||
		*type == 'R' ||
		*type == 'V'
	) {
		++type;
	}

	#define INDEXED_IVAR \
		((void *)((unsigned char *)object_getIndexedIvars(self) + offset))

	#define SET_ATOMIC_VAR(VARTYPE, CASTYPE) \
		VARTYPE existingValue; \
		VARTYPE volatile * backingVar = INDEXED_IVAR; \
		\
		for (;;) { \
			existingValue = *backingVar; \
			if (OSAtomicCompareAndSwap ## CASTYPE ## Barrier(existingValue, newValue, backingVar)) { \
				break; \
			} \
		} \
	
	#define SYNTHESIZE_COMPATIBLE_PRIMITIVE(RETTYPE, VARTYPE, CASTYPE) \
		do { \
			if (atomic) { \
				id localGetter = blockMethod(id self){ \
					return *(volatile RETTYPE *)INDEXED_IVAR; \
				}; \
				\
				id localSetter = blockMethod(id self, RETTYPE newRealValue){ \
					VARTYPE newValue = (VARTYPE)newRealValue; \
					SET_ATOMIC_VAR(VARTYPE, CASTYPE); \
				}; \
				\
				*getter = [Block_copy(localGetter) autorelease]; \
				*setter = [Block_copy(localSetter) autorelease]; \
			} else { \
				id localGetter = blockMethod(id self){ \
					return *(RETTYPE *)INDEXED_IVAR; \
				}; \
				\
				id localSetter = blockMethod(id self, RETTYPE newRealValue){ \
					*(RETTYPE *)INDEXED_IVAR = newRealValue; \
				}; \
				\
				*getter = [Block_copy(localGetter) autorelease]; \
				*setter = [Block_copy(localSetter) autorelease]; \
			} \
		} while (0)
	
	#define SYNTHESIZE_PRIMITIVE(RETTYPE, VARTYPE, CASTYPE) \
		do { \
			if (atomic) { \
				id localGetter = blockMethod(id self){ \
					union { \
						VARTYPE backing; \
						RETTYPE real; \
					} u; \
					\
					u.backing = *(volatile VARTYPE *)INDEXED_IVAR; \
					return u.real; \
				}; \
				\
				id localSetter = blockMethod(id self, RETTYPE newRealValue){ \
					union { \
						VARTYPE backing; \
						RETTYPE real; \
					} u; \
					\
					u.backing = 0; \
					u.real = newRealValue; \
					VARTYPE newValue = u.backing; \
					\
					SET_ATOMIC_VAR(VARTYPE, CASTYPE); \
				}; \
				\
				*getter = [Block_copy(localGetter) autorelease]; \
				*setter = [Block_copy(localSetter) autorelease]; \
			} else { \
				id localGetter = blockMethod(id self){ \
					union { \
						VARTYPE backing; \
						RETTYPE real; \
					} u; \
					\
					u.backing = *(VARTYPE *)INDEXED_IVAR; \
					return u.real; \
				}; \
				\
				id localSetter = blockMethod(id self, RETTYPE newRealValue){ \
					union { \
						VARTYPE backing; \
						RETTYPE real; \
					} u; \
					\
					u.backing = 0; \
					u.real = newRealValue; \
					\
					*(VARTYPE *)INDEXED_IVAR = u.backing; \
				}; \
				\
				*getter = [Block_copy(localGetter) autorelease]; \
				*setter = [Block_copy(localSetter) autorelease]; \
			} \
		} while (0)

	switch (*type) {
	case 'c':
		SYNTHESIZE_PRIMITIVE(char, int, Int);
		break;
	
	case 'i':
		SYNTHESIZE_COMPATIBLE_PRIMITIVE(int, int, Int);
		break;
	
	case 's':
		SYNTHESIZE_PRIMITIVE(short, int, Int);
		break;
	
	case 'l':
		SYNTHESIZE_COMPATIBLE_PRIMITIVE(long, long, Long);
		break;
	
	case 'q':
		SYNTHESIZE_PRIMITIVE(long long, int64_t, 64);
		break;
	
	case 'C':
		SYNTHESIZE_PRIMITIVE(unsigned char, int, Int);
		break;
	
	case 'I':
		SYNTHESIZE_COMPATIBLE_PRIMITIVE(unsigned int, int, Int);
		break;
	
	case 'S':
		SYNTHESIZE_PRIMITIVE(unsigned short, int, Int);
		break;
	
	case 'L':
		SYNTHESIZE_COMPATIBLE_PRIMITIVE(unsigned long, long, Long);
		break;
	
	case 'Q':
		SYNTHESIZE_PRIMITIVE(unsigned long long, int64_t, 64);
		break;
	
	case 'f':
		if (sizeof(float) > sizeof(int32_t)) {
			SYNTHESIZE_PRIMITIVE(float, int64_t, 64);
		} else {
			SYNTHESIZE_PRIMITIVE(float, int32_t, 32);
		}

		break;
	
	case 'd':
		SYNTHESIZE_PRIMITIVE(double, int64_t, 64);
		break;
	
	case 'B':
		SYNTHESIZE_PRIMITIVE(_Bool, int, Int);
		break;
	
	case '*':
		SYNTHESIZE_COMPATIBLE_PRIMITIVE(char *, void *, Ptr);
		break;
	
	case '@':
		if (atomic) {
			id localGetter = blockMethod(id self){
				id value = *(volatile id *)INDEXED_IVAR;
				return [[value retain] autorelease];
			};

			id localSetter = blockMethod(id self, id newValue){
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

				SET_ATOMIC_VAR(void *, Ptr);

				if (memoryManagementPolicy != ext_propertyMemoryManagementPolicyAssign)
					[(id)existingValue release];
			};

			*getter = [Block_copy(localGetter) autorelease];
			*setter = [Block_copy(localSetter) autorelease];
		} else {
			id localGetter = blockMethod(id self){
				id value = *(id *)INDEXED_IVAR;
				return [[value retain] autorelease];
			};

			id localSetter = blockMethod(id self, id newValue){
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
				
				id *backingVar = INDEXED_IVAR;

				id existingValue = *backingVar;
				*backingVar = newValue;

				if (memoryManagementPolicy != ext_propertyMemoryManagementPolicyAssign)
					[existingValue release];
			};

			*getter = [Block_copy(localGetter) autorelease];
			*setter = [Block_copy(localSetter) autorelease];
		}
		
		break;
	
	case '#':
		SYNTHESIZE_COMPATIBLE_PRIMITIVE(Class, void *, Ptr);
		break;
	
	case ':':
		SYNTHESIZE_COMPATIBLE_PRIMITIVE(SEL, void *, Ptr);
		break;
	
	case '[':
		NSLog(@"Cannot synthesize property for array with type code \"%s\"", type);
		return;
	
	case 'b':
		NSLog(@"Cannot synthesize property for bitfield with type code \"%s\"", type);
		return;
	
	case '{':
		NSLog(@"Cannot synthesize property for struct with type code \"%s\"", type);
		return;
		
	case '(':
		NSLog(@"Cannot synthesize property for union with type code \"%s\"", type);
		return;
	
	case '^':
		switch (type[1]) {
		case 'c':
		case 'C':
			SYNTHESIZE_COMPATIBLE_PRIMITIVE(char *, void *, Ptr);
			break;
		
		case 'i':
		case 'I':
			SYNTHESIZE_COMPATIBLE_PRIMITIVE(int *, void *, Ptr);
			break;
		
		case 's':
		case 'S':
			SYNTHESIZE_COMPATIBLE_PRIMITIVE(short *, void *, Ptr);
			break;
		
		case 'l':
		case 'L':
			SYNTHESIZE_COMPATIBLE_PRIMITIVE(long *, void *, Ptr);
			break;
		
		case 'q':
		case 'Q':
			SYNTHESIZE_COMPATIBLE_PRIMITIVE(long long *, void *, Ptr);
			break;
		
		case 'f':
			SYNTHESIZE_COMPATIBLE_PRIMITIVE(float *, void *, Ptr);
			break;
		
		case 'd':
			SYNTHESIZE_COMPATIBLE_PRIMITIVE(double *, void *, Ptr);
			break;
		
		case 'B':
			SYNTHESIZE_COMPATIBLE_PRIMITIVE(_Bool *, void *, Ptr);
			break;
		
		case 'v':
			SYNTHESIZE_COMPATIBLE_PRIMITIVE(void *, void *, Ptr);
			break;
		
		case '*':
		case '@':
		case '#':
		case '^':
		case '[':
			SYNTHESIZE_COMPATIBLE_PRIMITIVE(void **, void *, Ptr);
			break;
		
		case ':':
			SYNTHESIZE_COMPATIBLE_PRIMITIVE(SEL *, void *, Ptr);
			break;
		
		case '{':
			SYNTHESIZE_COMPATIBLE_PRIMITIVE(empty_struct_ptr_t, void *, Ptr);
			break;
		
		case '(':
			SYNTHESIZE_COMPATIBLE_PRIMITIVE(empty_union_ptr_t, void *, Ptr);
			break;

		case '?':
			SYNTHESIZE_COMPATIBLE_PRIMITIVE(IMP *, void *, Ptr);
			break;
		
		case 'b':
		default:
			NSLog(@"Cannot synthesize property for unknown pointer type with type code \"%s\"", type);
			return;
		}
		
		break;
	
	case '?':
		// this is PROBABLY a function pointer, but the documentation
		// leaves room open for uncertainty, so at least log a message
		NSLog(@"Assuming type code \"%s\" is a function pointer", type);

		// using a backing variable of void * would be unsafe, since function
		// pointers and pointers may be different sizes
		SYNTHESIZE_PRIMITIVE(IMP, int64_t, 64);
		break;
		
	default:
		NSLog(@"Unexpected type code \"%s\", cannot synthesize property", type);
	}

	#undef SET_ATOMIC_VAR
	#undef SYNTHESIZE_PRIMITIVE
	#undef SYNTHESIZE_COMPATIBLE_PRIMITIVE
}

size_t ext_addIndexedIvar (Class aClass, size_t ivarSize, size_t ivarAlignment) {
	NSUInteger offset;

	/*
	 * set up an autorelease pool in case any Cocoa classes invoke +initialize
	 * during this process
	 */
	@autoreleasepool {
		NSNumber *num = objc_getAssociatedObject(aClass, kIndexedIvarSizeKey);
		offset = [num unsignedIntegerValue];

		// align to ivarAlignment
		if ((offset & (ivarAlignment - 1)) != 0) {
			// round up to a multiple of ivarAlignment
			offset = (offset & (ivarAlignment - 1)) + ivarAlignment;
		}

		num = [NSNumber numberWithUnsignedInteger:offset + ivarSize];
		objc_setAssociatedObject(aClass, kIndexedIvarSizeKey, num, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

		Method allocWithZone = class_getClassMethod(aClass, @selector(allocWithZone:));
		if (method_getImplementation(allocWithZone) != (IMP)&ext_allocWithZonePlusIndexedIvars) {
			class_replaceMethod(
				object_getClass(aClass),
				@selector(allocWithZone:),
				(IMP)&ext_allocWithZonePlusIndexedIvars,
				method_getTypeEncoding(allocWithZone)
			);
		}
	}

	return offset;
}
