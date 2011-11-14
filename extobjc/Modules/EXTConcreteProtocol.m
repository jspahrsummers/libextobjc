/*
 *  EXTConcreteProtocol.m
 *  extobjc
 *
 *  Created by Justin Spahr-Summers on 2010-11-10.
 *  Released into the public domain.
 */

#import "EXTConcreteProtocol.h"
#import "EXTRuntimeExtensions.h"
#import <pthread.h>
#import <stdlib.h>

/*
 * To actually load a concrete protocol, we must find every class conforming to
 * the protocol, and then add the concrete methods to each such class in
 * a non-destructive fashion.
 *
 * For optimization reasons, though, we don't want to perform this work every
 * time a concrete protocol is encountered. What actually happens below is that
 * each concrete protocol is added to an array as it's loaded into memory, and
 * then, after all Objective-C runtime setup, the concrete protocols are
 * injected into any classes conforming to them. In this way, the brunt of the
 * work happens only once per application lifecycle.
 */

// contains the information needed to reference a full concrete protocol
typedef struct {
	// the container class used to hold the concrete methods of this protocol
	Class methodContainer;

	// the actual protocol declaration (@protocol block)
	__unsafe_unretained Protocol *protocol;

	// whether both of the above objects have been fully loaded and prepared in
	// memory
	//
	// this does NOT refer to a concrete protocol having been injected already
	BOOL loaded;
} EXTConcreteProtocol;

/**
 * This comparison function is intended to be used with qsort(), and will
 * compare concrete protocols to determine load priority. If a concrete protocol
 * conforms to another concrete protocol, the former will be prioritized above
 * the latter; this way, a descendant protocol can redefine the default methods
 * in a "parent."
 */
static
int ext_compareConcreteProtocolLoadPriority (const void *a, const void *b) {
	// if the pointers are equal, it must be the same protocol
	if (a == b)
		return 0;
	
	const EXTConcreteProtocol *protoA = a;
	const EXTConcreteProtocol *protoB = b;

	// if A conforms to B, A should come first
	if (protocol_conformsToProtocol(protoA->protocol, protoB->protocol))
		return -1;
	// if B conforms to A, B should come first
	else if (protocol_conformsToProtocol(protoB->protocol, protoA->protocol))
		return 1;
	// otherwise, enforce a total ordering (but we really don't care which way
	// it goes)
	else if (protoA < protoB)
		return -1;
	else
		return 1;
}

// the full list of concrete protocols (an array of EXTConcreteProtocol structs)
static EXTConcreteProtocol * restrict concreteProtocols = NULL;

// the number of concrete protocols stored in the array
static size_t concreteProtocolCount = 0;

// the total capacity of the array
// we use a doubling algorithm to amortize the cost of insertion, so this is
// generally going to be a power-of-two
static size_t concreteProtocolCapacity = 0;

// the number of EXTConcreteProtocols which have been loaded into memory (though
// not necessary injected)
//
// in other words, the total count which have 'loaded' set to YES
static size_t concreteProtocolsLoaded = 0;

// a mutex is used to guard against multiple threads changing the above static
// variables
static pthread_mutex_t concreteProtocolsLock = PTHREAD_MUTEX_INITIALIZER;

/**
 * This function actually performs the hard work. It obtains a full list of all
 * classes registered with the Objective-C runtime, finds those conforming to
 * concrete protocols, and then adds the methods as appropriate.
 *
 * This function can safely be called multiple times with no ill effect, as the
 * methods here will never overwrite any pre-existing ones.
 */
static
void ext_injectConcreteProtocols (void) {
	/*
	 * don't lock concreteProtocolsLock in this function, as it is called only
	 * from public functions which already perform the synchronization
	 */
	
	// re-sort the concrete protocols list to prioritize dependencies (see the
	// comments in ext_compareConcreteProtocolLoadPriority)
	qsort(
		concreteProtocols,
		concreteProtocolCount,
		sizeof(EXTConcreteProtocol),
		&ext_compareConcreteProtocolLoadPriority
	);

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
	@autoreleasepool {

	// loop through the concrete protocols, and apply each one to all the
	// classes in turn
	//
	// ORDER IS IMPORTANT HERE: protocols have to be injected to all classes in
	// the order in which they appear in concreteProtocols. Consider classes
	// X and Y that implement protocols A and B, respectively. B needs to get
	// its implementation into Y before A gets into X (which would block the
	// injection of B).
		for (size_t i = 0;i < concreteProtocolCount;++i) {
			Protocol *protocol = concreteProtocols[i].protocol;

			// get the class containing the methods of this concrete protocol
			Class containerClass = concreteProtocols[i].methodContainer;

			// get the full list of instance methods implemented by the concrete
			// protocol
			unsigned imethodCount = 0;
			Method *imethodList = class_copyMethodList(containerClass, &imethodCount);

			// get the full list of class methods implemented by the concrete
			// protocol
			unsigned cmethodCount = 0;
			Method *cmethodList = class_copyMethodList(object_getClass(containerClass), &cmethodCount);

			// loop through all classes
			for (unsigned classIndex = 0;classIndex < classCount;++classIndex) {
				Class class = allClasses[classIndex];
				
				// if this class doesn't conform to the protocol, continue to the
				// next class immediately
				if (!class_conformsToProtocol(class, protocol))
					continue;

				// get the metaclass of this class (the object on which class
				// methods are implemented)
				Class metaclass = object_getClass(class);

				// inject all instance methods in the concrete protocol
				for (unsigned methodIndex = 0;methodIndex < imethodCount;++methodIndex) {
					Method method = imethodList[methodIndex];
					SEL selector = method_getName(method);

					// first, check to see if such an instance method already exists
					// (on this class or on a superclass)
					if (class_getInstanceMethod(class, selector)) {
						// it does exist, so don't overwrite it
						continue;
					}

					// add this instance method to the class in question
					IMP imp = method_getImplementation(method);
					const char *types = method_getTypeEncoding(method);
					if (!class_addMethod(class, selector, imp, types)) {
						fprintf(stderr, "ERROR: Could not implement instance method -%s from concrete protocol %s on class %s\n",
							sel_getName(selector), protocol_getName(protocol), class_getName(class));
					}
				}

				// inject all class methods in the concrete protocol
				for (unsigned methodIndex = 0;methodIndex < cmethodCount;++methodIndex) {
					Method method = cmethodList[methodIndex];
					SEL selector = method_getName(method);

					// +initialize is a special case that should never be copied
					// into a class, as it performs initialization for the concrete
					// protocol
					if (selector == @selector(initialize)) {
						// so just continue looking through the rest of the methods
						continue;
					}

					// first, check to see if a class method already exists (on this
					// class or on a superclass)
					//
					// since 'class' is considered to be an instance of 'metaclass',
					// this is actually checking for class methods (despite the
					// function name)
					if (class_getInstanceMethod(metaclass, selector)) {
						// it does exist, so don't overwrite it
						continue;
					}

					// add this class method to the metaclass in question
					IMP imp = method_getImplementation(method);
					const char *types = method_getTypeEncoding(method);
					if (!class_addMethod(metaclass, selector, imp, types)) {
						fprintf(stderr, "ERROR: Could not implement class method +%s from concrete protocol %s on class %s\n",
							sel_getName(selector), protocol_getName(protocol), class_getName(class));
					}
				}
			}

			// free the instance method list
			free(imethodList); imethodList = NULL;

			// free the class method list
			free(cmethodList); cmethodList = NULL;

			// use [containerClass class] and discard the result to call +initialize
			// on containerClass if it hasn't been called yet
			//
			// this is to allow the concrete protocol to perform custom initialization
			(void)[containerClass class];
		}

	// drain the temporary autorelease pool
	}

	// free the allocated class list
	free(allClasses);

	// now that everything's injected, the concrete protocol list can also be
	// destroyed
	//
	// in the future, it may actually be valuable to keep the list around so it
	// can be queried
	free(concreteProtocols); concreteProtocols = NULL;
	concreteProtocolCount = 0;
	concreteProtocolCapacity = 0;
	concreteProtocolsLoaded = 0;
}

/**
 * Adds a concrete protocol identified by \a protocol and \a methodContainer to
 * our global list. Returns \c YES on success.
 *
 * Objective-C runtime functions should not be used here, as they will sometimes
 * call through to special methods (e.g., +initialize), and no autorelease pool
 * has been set up.
 */
BOOL ext_addConcreteProtocol (Protocol *protocol, Class methodContainer) {
	if (!protocol || !methodContainer)
		return NO;
	
	// lock the mutex to prevent accesses from other threads while we perform
	// this work
	if (pthread_mutex_lock(&concreteProtocolsLock) != 0) {
		fprintf(stderr, "ERROR: Could not synchronize on concrete protocol data\n");
		return NO;
	}
	
	// if we've hit the hard maximum for number of concrete protocols, we can't
	// continue
	if (concreteProtocolCount == SIZE_MAX) {
		pthread_mutex_unlock(&concreteProtocolsLock);
		return NO;
	}

	// if the array has no more space, we will need to allocate additional
	// entries
	if (concreteProtocolCount >= concreteProtocolCapacity) {
		size_t newCapacity;
		if (concreteProtocolCapacity == 0)
			// if there are no entries, make space for just one
			newCapacity = 1;
		else {
			// otherwise, double the current capacity
			newCapacity = concreteProtocolCapacity << 1;

			// if the new capacity is less than the current capacity, that's
			// unsigned integer overflow
			if (newCapacity < concreteProtocolCapacity) {
				// set it to the maximum possible instead
				newCapacity = SIZE_MAX;

				// if the new capacity is still not greater than the current
				// (for instance, if it was already SIZE_MAX), we can't continue
				if (newCapacity <= concreteProtocolCapacity) {
					pthread_mutex_unlock(&concreteProtocolsLock);
					return NO;
				}
			}
		}

		// we have a new capacity, so resize the list of all concrete protocols
		// to add the new entries
		void * restrict ptr = realloc(concreteProtocols, sizeof(EXTConcreteProtocol) * newCapacity);
		if (!ptr) {
			// the allocation failed, abort
			pthread_mutex_unlock(&concreteProtocolsLock);
			return NO;
		}

		// update the file statics with the new array's info
		concreteProtocols = ptr;
		concreteProtocolCapacity = newCapacity;
	}

	// at this point, there absolutely must be at least one empty entry in the
	// array
	assert(concreteProtocolCount < concreteProtocolCapacity);

	// construct a new EXTConcreteProtocol structure and add it to the first
	// empty space in the array, incrementing concreteProtocolCount in the
	// process
	concreteProtocols[concreteProtocolCount++] = (EXTConcreteProtocol){
		.methodContainer = methodContainer,
		.protocol = protocol,
		.loaded = NO
	};

	pthread_mutex_unlock(&concreteProtocolsLock);

	// success!
	return YES;
}

/**
 * Marks a concrete protocol, identified by \a protocol, as being fully loaded
 * by the Objective-C runtime. If all concrete protocols are now loaded, this
 * will invoke #ext_injectConcreteProtocols to actually add the concrete methods
 * into conforming classes.
 */
void ext_loadConcreteProtocol (Protocol *protocol) {
	if (!protocol)
		return;
	
	// lock the mutex to prevent accesses from other threads while we perform
	// this work
	if (pthread_mutex_lock(&concreteProtocolsLock) != 0) {
		fprintf(stderr, "ERROR: Could not synchronize on concrete protocol data\n");
		return;
	}

	// loop through all the concrete protocols in our list, trying to find the
	// one associated with 'protocol'
	for (size_t i = 0;i < concreteProtocolCount;++i) {
		if (concreteProtocols[i].protocol == protocol) {
			// found the matching concrete protocol, check to see if it's
			// already loaded
			if (!concreteProtocols[i].loaded) {
				// if it's not, mark it as being loaded now
				concreteProtocols[i].loaded = YES;

				// since this concrete protocol was in our array, and it was not
				// loaded, the total number of protocols loaded must be less
				// than the total count at this point in time
				assert(concreteProtocolsLoaded < concreteProtocolCount);

				// ... and then increment the total number of concrete protocols
				// loaded – if it now matches the total count of concrete
				// protocols, begin the injection process
				if (++concreteProtocolsLoaded == concreteProtocolCount)
					ext_injectConcreteProtocols();
			}

			break;
		}
	}

	pthread_mutex_unlock(&concreteProtocolsLock);
}

