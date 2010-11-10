/*
 *  EXTConcreteProtocol.m
 *  extobjc
 *
 *  Created by Justin Spahr-Summers on 2010-11-10.
 *  Released into the public domain.
 */

#import "EXTConcreteProtocol.h"
#import <pthread.h>
#import <stdio.h>
#import <stdlib.h>

typedef struct {
	Class methodContainer;
	Protocol *protocol;
	BOOL loaded;
} EXTConcreteProtocol;

static pthread_mutex_t concreteProtocolsLock = PTHREAD_MUTEX_INITIALIZER;
static EXTConcreteProtocol * restrict concreteProtocols = NULL;
static size_t concreteProtocolCount = 0;
static size_t concreteProtocolCapacity = 0;
static size_t concreteProtocolsLoaded = 0;

static
void ext_injectConcreteProtocols (void) {
	/*
	 * don't lock concreteProtocolsLock in this function, as it is called only
	 * from public functions which already perform the synchronization
	 */

	int classCount = objc_getClassList(NULL, 0);
	Class *allClasses = malloc(sizeof(Class) * classCount);
	if (!allClasses) {
		fprintf(stderr, "ERROR: Could not obtain list of all classes\n");
		return;
	}

	classCount = objc_getClassList(allClasses, classCount);

	for (size_t i = 0;i < concreteProtocolCount;++i) {
		Protocol *protocol = concreteProtocols[i].protocol;
		Class containerClass = concreteProtocols[i].methodContainer;

		unsigned imethodCount = 0;
		Method *imethodList = class_copyMethodList(containerClass, &imethodCount);

		unsigned cmethodCount = 0;
		Method *cmethodList = class_copyMethodList(object_getClass(containerClass), &cmethodCount);

		if (!imethodCount && !cmethodCount) {
			// just in case the returned arrays are NULL-terminated
			free(imethodList);
			free(cmethodList);
			continue;
		}

		for (int classIndex = 0;classIndex < classCount;++classIndex) {
			Class class = allClasses[classIndex];
			if (!class_conformsToProtocol(class, protocol))
				continue;

			for (unsigned methodIndex = 0;methodIndex < imethodCount;++methodIndex) {
				Method method = imethodList[methodIndex];
				SEL selector = method_getName(method);

				if (class_getInstanceMethod(class, selector)) {
					/*
					 * don't override implementations, even those of
					 * a superclass
					 */
					continue;
				}

				IMP imp = method_getImplementation(method);
				const char *types = method_getTypeEncoding(method);

				if (!class_addMethod(class, selector, imp, types)) {
					fprintf(stderr, "ERROR: Could not implement instance method %s from concrete protocol %s on class %s\n",
						sel_getName(selector), protocol_getName(protocol), class_getName(class));
				}
			}

			Class metaclass = object_getClass(class);
			for (unsigned methodIndex = 0;methodIndex < cmethodCount;++methodIndex) {
				Method method = cmethodList[methodIndex];
				SEL selector = method_getName(method);

				/* this actually checks for class methods (instance of the
				 * metaclass) */
				if (class_getInstanceMethod(metaclass, selector)) {
					/*
					 * don't override implementations, even those of
					 * a superclass
					 */
					continue;
				}

				IMP imp = method_getImplementation(method);
				const char *types = method_getTypeEncoding(method);

				if (!class_addMethod(metaclass, selector, imp, types)) {
					fprintf(stderr, "ERROR: Could not implement class method %s from concrete protocol %s on class %s\n",
						sel_getName(selector), protocol_getName(protocol), class_getName(class));
				}
			}
		}

		free(imethodList);
		free(cmethodList);
	}

	free(allClasses);
}

BOOL ext_addConcreteProtocol (Protocol *protocol, Class methodContainer) {
	if (!protocol || !methodContainer)
		return NO;
	
	if (pthread_mutex_lock(&concreteProtocolsLock) != 0) {
		fprintf(stderr, "ERROR: Could not synchronize on concrete protocol data\n");
		return NO;
	}
	
	if (concreteProtocolCount == SIZE_MAX) {
		pthread_mutex_unlock(&concreteProtocolsLock);
		return NO;
	}

	if (concreteProtocolCount >= concreteProtocolCapacity) {
		size_t newCapacity;
		if (concreteProtocolCapacity == 0)
			newCapacity = 1;
		else {
			newCapacity = concreteProtocolCapacity << 1;
			if (newCapacity < concreteProtocolCapacity) {
				newCapacity = SIZE_MAX;
				if (newCapacity <= concreteProtocolCapacity) {
					pthread_mutex_unlock(&concreteProtocolsLock);
					return NO;
				}
			}
		}

		void * restrict ptr = realloc(concreteProtocols, sizeof(EXTConcreteProtocol) * newCapacity);
		if (!ptr) {
			pthread_mutex_unlock(&concreteProtocolsLock);
			return NO;
		}

		concreteProtocols = ptr;
		concreteProtocolCapacity = newCapacity;
	}

	assert(concreteProtocolCount < concreteProtocolCapacity);

	concreteProtocols[concreteProtocolCount++] = (EXTConcreteProtocol){
		.methodContainer = methodContainer,
		.protocol = protocol,
		.loaded = NO
	};

	pthread_mutex_unlock(&concreteProtocolsLock);
	return YES;
}

void ext_loadConcreteProtocol (Protocol *protocol) {
	if (!protocol)
		return;
	
	if (pthread_mutex_lock(&concreteProtocolsLock) != 0) {
		fprintf(stderr, "ERROR: Could not synchronize on concrete protocol data\n");
		return;
	}

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

	pthread_mutex_unlock(&concreteProtocolsLock);
}

