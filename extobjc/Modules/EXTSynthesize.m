//
//  EXTSynthesize.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-05-12.
//  Released into the public domain.
//

#import "EXTSynthesize.h"
#import "EXTBlockMethod.h"

void ext_synthesizePropertiesForClass (Class cls) {
	unsigned count = 0;
	objc_property_t *properties = class_copyPropertyList(cls, &count);

	unsigned methodCount = 0;
	Method *methods = class_copyMethodList(cls, &methodCount);

	const char *idType = @encode(id);
	const char *selType = @encode(SEL);
	const char *voidType = @encode(void);

	size_t idLen = strlen(idType);
	size_t selLen = strlen(selType);
	size_t idSelLen = idLen + selLen;
	size_t voidLen = strlen(voidType);

	for (unsigned i = 0;i < count;++i) {
		ext_propertyAttributes *attribs = ext_copyPropertyAttributes(properties[i]);

		// if 'ivar' is NULL, this property is @dynamic, and we should not
		// synthesize something for it
		if (attribs->ivar) {
			BOOL foundGetter = NO;
			BOOL foundSetter = NO;

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

			// if no getter exists, or a setter should exist but does not, we
			// should synthesize something
			if (!foundGetter || (!foundSetter && !attribs->readonly)) {
				ext_blockGetter getter = nil;
				ext_blockSetter setter = nil;

				// TODO: use an existing Ivar if possible

				ext_synthesizeBlockProperty(
					attribs->type,
					attribs->memoryManagementPolicy,
					!attribs->nonatomic,
					&getter,
					&setter
				);

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

		free(attribs);
	}

	free(methods);
	free(properties);
}
