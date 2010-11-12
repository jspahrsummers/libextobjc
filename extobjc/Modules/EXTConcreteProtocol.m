/*
 *  EXTConcreteProtocol.m
 *  extobjc
 *
 *  Created by Justin Spahr-Summers on 2010-11-10.
 *  Released into the public domain.
 */

#import "EXTConcreteProtocol.h"
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
	Protocol *protocol;

	// whether both of the above objects have been fully loaded and prepared in
	// memory
	//
	// this does NOT refer to a concrete protocol having been injected already
	BOOL loaded;
} EXTConcreteProtocol;

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

	// get the number of classes registered with the runtime
	int classCount = objc_getClassList(NULL, 0);

	// allocate space for them
	Class *allClasses = malloc(sizeof(Class) * classCount);
	if (!allClasses) {
		fprintf(stderr, "ERROR: Could allocate memory for all classes\n");
		return;
	}

	// and then actually pull the list of the class objects
	classCount = objc_getClassList(allClasses, classCount);

	// now, loop through the concrete protocols, and apply each one to this full
	// class list in turn
	//
	// doing this with the protocol outer loop avoids allocating and tearing
	// down the protocol's methods on each inner loop iteration (instead, doing
	// it once per outer loop iteration) – whether this is advantageous really
	// depends on the use case, but performance should be good enough either
	// way, as this only happens once
	for (size_t i = 0;i < concreteProtocolCount;++i) {
		// pull the information from the concrete protocol structure
		Protocol *protocol = concreteProtocols[i].protocol;
		Class containerClass = concreteProtocols[i].methodContainer;

		// get the full list of instance methods implemented by the concrete
		// protocol
		unsigned imethodCount = 0;
		Method *imethodList = class_copyMethodList(containerClass, &imethodCount);

		// get the full list of class methods implemented by the concrete
		// protocol
		unsigned cmethodCount = 0;
		Method *cmethodList = class_copyMethodList(object_getClass(containerClass), &cmethodCount);

		// if there are neither, don't even bother looping over all the
		// classes... simply jump to the next loop iteration now
		if (!imethodCount && !cmethodCount) {
			// we free these arrays just in case they're NULL-terminated (which
			// would mean that they are one-item arrays containing just a NULL
			// entry)
			//
			// and, of course, freeing NULL has no effect
			free(imethodList);
			free(cmethodList);
			continue;
		}

		// loop through all classes
		for (int classIndex = 0;classIndex < classCount;++classIndex) {
			Class class = allClasses[classIndex];
			
			// if this class doesn't conform to the protocol, continue to the
			// next class immediately
			if (!class_conformsToProtocol(class, protocol))
				continue;

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
					fprintf(stderr, "ERROR: Could not implement instance method %s from concrete protocol %s on class %s\n",
						sel_getName(selector), protocol_getName(protocol), class_getName(class));
				}
			}

			// get the metaclass of this class (the object on which class
			// methods are implemented)
			Class metaclass = object_getClass(class);

			// and then inject all class methods in the concrete protocol
			for (unsigned methodIndex = 0;methodIndex < cmethodCount;++methodIndex) {
				Method method = cmethodList[methodIndex];
				SEL selector = method_getName(method);

				// first, check to see if a class method already eixsts (on this
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
					fprintf(stderr, "ERROR: Could not implement class method %s from concrete protocol %s on class %s\n",
						sel_getName(selector), protocol_getName(protocol), class_getName(class));
				}
			}
		}

		// free the copied method lists
		free(imethodList);
		free(cmethodList);
	}

	// free the allocated class list
	free(allClasses);
}

/**
 * Adds a concrete protocol identified by \a protocol and \a methodContainer to
 * our global list. Returns \c YES on success.
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

