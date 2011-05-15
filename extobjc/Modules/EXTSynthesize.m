//
//  EXTSynthesize.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-05-12.
//  Released into the public domain.
//

#import "EXTSynthesize.h"
#import "EXTBlockMethod.h"

#define DEBUG_LOGGING 1

//void ext_synthesizeBlockProperty (const char * restrict type, ext_propertyMemoryManagementPolicy memoryManagementPolicy, BOOL atomic, ext_blockGetter * restrict getter, ext_blockSetter * restrict setter);

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

			// TODO: THIS DOES NOT WORK FOR MULTIPLE INSTANCES OF A CLASS!
			ext_synthesizeBlockProperty(
				attribs->type,
				attribs->memoryManagementPolicy,
				!attribs->nonatomic,
				&getter,
				&setter
			);

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
