/*
 *  EXTConcreteProtocol.m
 *  extobjc
 *
 *  Created by Justin Spahr-Summers on 2010-11-10.
 *  Released into the public domain.
 */

#import "EXTConcreteProtocol.h"

typedef struct {
	Class methodContainer;
	Protocol *protocol;
	BOOL loaded;
} EXTConcreteProtocol;

static EXTConcreteProtocol * restrict concreteProtocols = NULL;
static size_t concreteProtocolCount = 0;
static size_t concreteProtocolCapacity = 0;
static size_t concreteProtocolsLoaded = 0;

static
void ext_injectConcreteProtocols (void) {
}

BOOL ext_addConcreteProtocol (Protocol *protocol, Class methodContainer) {
	if (concreteProtocolCount == SIZE_MAX)
		return NO;
	else if (concreteProtocolCount >= concreteProtocolCapacity) {
		size_t newCapacity = concreteProtocolCapacity << 1;
		if (newCapacity < concreteProtocolCapacity) {
			newCapacity = SIZE_MAX;
			if (newCapacity <= concreteProtocolCapacity)
				return NO;
		}

		void * restrict ptr = realloc(concreteProtocols, sizeof(EXTConcreteProtocol) * newCapacity);
		if (!ptr)
			return NO;

		concreteProtocols = ptr;
		concreteProtocolCapacity = newCapacity;
	}

	concreteProtocols[concreteProtocolCount++] = (EXTConcreteProtocol){
		.methodContainer = methodContainer,
		.protocol = protocol,
		.loaded = NO
	};

	return YES;
}

void ext_loadConcreteProtocol (Protocol *protocol) {
	for (size_t i = 0;i < concreteProtocolCount;++i) {
		if (concreteProtocols[i].protocol == protocol) {
			if (!concreteProtocols[i].loaded) {
				concreteProtocols[i].loaded = YES;

				assert(concreteProtocolsLoaded < concreteProtocolCount);
				if (++concreteProtocolsLoaded == concreteProtocolCount)
					ext_injectConcreteProtocols();
			}

			break;
		}
	}
}

