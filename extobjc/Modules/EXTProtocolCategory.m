/*
 *  EXTProtocolCategory.m
 *  extobjc
 *
 *  Created by Justin Spahr-Summers on 2010-11-13.
 *  Released into the public domain.
 */

#import "EXTProtocolCategory.h"
#import "EXTRuntimeExtensions.h"
#import <pthread.h>
#import <stdlib.h>

/*
 * The implementation in this file is very similar in concept to that of
 * EXTConcreteProtocol, except that there is no inheritance between
 * EXTProtocolCategories, and methods are injected DESTRUCTIVELY (rather than
 * non-destructively in all cases). If the code here doesn't make much sense or
 * isn't commented well-enough, see EXTConcreteProtocol for a more thorough
 * explanation.
 */

typedef struct {
	Class methodContainer;
	__unsafe_unretained Protocol *protocol;
	BOOL loaded;
} EXTProtocolCategory;

static EXTProtocolCategory * restrict protocolCategories = NULL;
static size_t protocolCategoryCount = 0;
static size_t protocolCategoryCapacity = 0;
static size_t protocolCategoriesLoaded = 0;
static pthread_mutex_t protocolCategoriesLock = PTHREAD_MUTEX_INITIALIZER;

static
void ext_injectProtocolCategories (void) {
	/*
	 * don't lock protocolCategoriesLock in this function, as it is called only
	 * from public functions which already perform the synchronization
	 */
	
	unsigned classCount = 0;
	Class *allClasses = ext_copyClassList(&classCount);

	if (!classCount || !allClasses) {
		fprintf(stderr, "ERROR: No classes registered with the runtime\n");
		return;
	}

	/*
	 * set up an autorelease pool in case any Cocoa classes get used during
	 * the injection process or +initialize
	 */
	NSAutoreleasePool *pool = [NSAutoreleasePool new];

	for (unsigned classIndex = 0;classIndex < classCount;++classIndex) {
		Class class = allClasses[classIndex];

		for (size_t i = 0;i < protocolCategoryCount;++i) {
			Protocol *protocol = protocolCategories[i].protocol;
			if (!class_conformsToProtocol(class, protocol))
				continue;

			Class containerClass = protocolCategories[i].methodContainer;

			ext_injectMethodsFromClass(
				containerClass,
				class,

				// +initialize is a special case that should never be copied
				// into a class, as it performs initialization for the protocol
				// category
				ext_methodInjectionIgnoreInitialize,
				NULL
			);

			// use [containerClass class] and discard the result to call +initialize
			// on containerClass if it hasn't been called yet
			//
			// this is to allow the protocol category to perform custom initialization
			(void)[containerClass class];
		}
	}

	[pool drain];

	free(allClasses);

	// now that everything's injected, the protocol category list should be
	// destroyed
	free(protocolCategories); protocolCategories = NULL;
	protocolCategoryCount = 0;
	protocolCategoryCapacity = 0;
	protocolCategoriesLoaded = 0;
}

BOOL ext_addProtocolCategory (Protocol *protocol, Class methodContainer) {
	if (!protocol || !methodContainer)
		return NO;
	
	if (pthread_mutex_lock(&protocolCategoriesLock) != 0) {
		fprintf(stderr, "ERROR: Could not synchronize on protocol category data\n");
		return NO;
	}
	
	if (protocolCategoryCount == SIZE_MAX) {
		pthread_mutex_unlock(&protocolCategoriesLock);
		return NO;
	}

	if (protocolCategoryCount >= protocolCategoryCapacity) {
		size_t newCapacity;
		if (protocolCategoryCapacity == 0)
			newCapacity = 1;
		else {
			newCapacity = protocolCategoryCapacity << 1;
			if (newCapacity < protocolCategoryCapacity) {
				newCapacity = SIZE_MAX;
				if (newCapacity <= protocolCategoryCapacity) {
					pthread_mutex_unlock(&protocolCategoriesLock);
					return NO;
				}
			}
		}

		void * restrict ptr = realloc(protocolCategories, sizeof(EXTProtocolCategory) * newCapacity);
		if (!ptr) {
			pthread_mutex_unlock(&protocolCategoriesLock);
			return NO;
		}

		protocolCategories = ptr;
		protocolCategoryCapacity = newCapacity;
	}

	assert(protocolCategoryCount < protocolCategoryCapacity);

	protocolCategories[protocolCategoryCount++] = (EXTProtocolCategory){
		.methodContainer = methodContainer,
		.protocol = protocol,
		.loaded = NO
	};

	pthread_mutex_unlock(&protocolCategoriesLock);
	return YES;
}

void ext_loadProtocolCategory (Protocol *protocol) {
	if (!protocol)
		return;
	
	if (pthread_mutex_lock(&protocolCategoriesLock) != 0) {
		fprintf(stderr, "ERROR: Could not synchronize on protocol category data\n");
		return;
	}

	for (size_t i = 0;i < protocolCategoryCount;++i) {
		if (protocolCategories[i].protocol == protocol) {
			if (!protocolCategories[i].loaded) {
				protocolCategories[i].loaded = YES;

				assert(protocolCategoriesLoaded < protocolCategoryCount);
				if (++protocolCategoriesLoaded == protocolCategoryCount)
					ext_injectProtocolCategories();
			}

			break;
		}
	}

	pthread_mutex_unlock(&protocolCategoriesLock);
}

