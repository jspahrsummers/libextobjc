//
//  EXTRuntimeExtensions.h
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-03-05.
//  Released into the public domain.
//

#import <objc/runtime.h>

/**
 * A callback indicating that the given method failed to be added to the given
 * class. The reason for the failure depends on the attempted task.
 */
typedef void (*ext_failedMethodCallback)(Class, Method);

/**
 * Used with #ext_injectMethods to determine injection behavior.
 */
typedef enum {
	/**
	 * Indicates that any existing methods on the destination class should be
	 * overwritten.
	 */
	ext_methodInjectionReplace                  = 0x00,

	/**
	 * Avoid overwriting methods on the immediate destination class.
	 */
	ext_methodInjectionFailOnExisting           = 0x01,
	
	/**
	 * Avoid overriding methods implemented in any superclass of the destination
	 * class.
	 */
	ext_methodInjectionFailOnSuperclassExisting = 0x02,

	/**
	 * Avoid overwriting methods implemented in the immediate destination class
	 * or any superclass. This is equivalent to
	 * <tt>ext_methodInjectionFailOnExisting | ext_methodInjectionFailOnSuperclassExisting</tt>.
	 */
	ext_methodInjectionFailOnAnyExisting        = 0x03,

	/**
	 * Ignore the \c +load class method. This does not affect instance method
	 * injection.
	 */
	ext_methodInjectionIgnoreLoad = 1U << 2,

	/**
	 * Ignore the \c +initialize class method. This does not affect instance method
	 * injection.
	 */
	ext_methodInjectionIgnoreInitialize = 1U << 3
} ext_methodInjectionBehavior;

/**
 * A mask for the overwriting behavior flags of #ext_methodInjectionBehavior.
 */
static const ext_methodInjectionBehavior ext_methodInjectionOverwriteBehaviorMask = 0x3;

/**
 * Iterates through the first \a count entries in \a methods and attempts to add
 * each one to \a aClass. If a method by the same name already exists on \a
 * aClass, it is \e not overridden. If \a checkSuperclasses is \c YES, and
 * a method by the same name already exists on any superclass of \a aClass, it
 * is not overridden.
 *
 * Returns the number of methods added successfully. For each method that fails
 * to be added, \a failedToAddCallback (if provided) is invoked.
 */
unsigned ext_addMethods (Class aClass, Method *methods, unsigned count, BOOL checkSuperclasses, ext_failedMethodCallback failedToAddCallback);

/**
 * Iterates through all instance and class methods of \a srcClass and attempts
 * to add each one to \a dstClass. If a method by the same name already exists
 * on \a aClass, it is \e not overridden. If \a checkSuperclasses is \c YES, and
 * a method by the same name already exists on any superclass of \a aClass, it
 * is not overridden.
 *
 * Returns the number of methods added successfully. For each method that fails
 * to be added, \a failedToAddCallback (if provided) is invoked.
 *
 * @note This ignores any \c +load method on \a srcClass. \a srcClass and \a
 * dstClass must not be metaclasses.
 */
unsigned ext_addMethodsFromClass (Class srcClass, Class dstClass, BOOL checkSuperclasses, ext_failedMethodCallback failedToAddCallback);

/**
 * Returns the full list of classes registered with the runtime, terminated with
 * \c NULL. If \a count is not \c NULL, it is filled in with the total number of
 * classes returned. You must \c free() the returned array.
 */
Class *ext_copyClassList (unsigned *count);

/**
 * Looks through the complete list of classes registered with the runtime and
 * finds all classes which conform to \a protocol. Returns \c *count classes
 * termined by a \c NULL. You must \c free() the returned array. If there are no
 * classes conforming to \a protocol, \c NULL is returned.
 *
 * @note \a count may be \c NULL.
 */
Class *ext_copyClassListConformingToProtocol (Protocol *protocol, unsigned *count);

/**
 * Looks through the complete list of classes registered with the runtime and
 * finds all classes which are descendant from \a aClass. Returns \c
 * *subclassCount classes terminated by a \c NULL. You must \c free() the
 * returned array. If there are no subclasses of \a aClass, \c NULL is
 * returned.
 *
 * @note \a subclassCount may be \c NULL. \a aClass may be a metaclass to get
 * all subclass metaclass objects.
 */
Class *ext_copySubclassList (Class aClass, unsigned *subclassCount);

/**
 * Finds the instance method named \a aSelector on \a aClass and returns it, or
 * returns \c NULL if no such instance method exists. Unlike \c
 * class_getInstanceMethod(), this does not search superclasses.
 *
 * @note To get class methods in this manner, use a metaclass for \a aClass.
 */
Method ext_getImmediateInstanceMethod (Class aClass, SEL aSelector);

/**
 * Returns the value of \c Ivar \a IVAR from instance \a OBJ. The instance
 * variable must be of type \a TYPE, and is returned as such.
 *
 * @warning Depending on the platform, this may or may not work with aggregate
 * or floating-point types.
 */
#define ext_getIvar(OBJ, IVAR, TYPE) \
	((TYPE (*)(id, Ivar)object_getIvar)((OBJ), (IVAR)))

/**
 * Returns the value of the instance variable identified by the string \a NAME
 * from instance \a OBJ. The instance variable must be of type \a TYPE, and is
 * returned as such.
 *
 * @note \a OBJ is evaluated twice.
 *
 * @warning Depending on the platform, this may or may not work with aggregate
 * or floating-point types.
 */
#define ext_getIvarByName(OBJ, NAME, TYPE) \
	ext_getIvar((OBJ), class_getInstanceVariable(object_getClass((OBJ)), (NAME)), TYPE)

/**
 * Highly-configurable method injection. Adds the first \a count entries from \a
 * methods into \a aClass according to \a behavior.
 *
 * Returns the number of methods added successfully. For each method that fails
 * to be added, \a failedToAddCallback (if provided) is invoked.
 */
unsigned ext_injectMethods (Class aClass, Method *methods, unsigned count, ext_methodInjectionBehavior behavior, ext_failedMethodCallback failedToAddCallback);

/**
 * Invokes #ext_injectMethods with the instance methods and class methods from
 * \a srcClass. #ext_methodInjectionIgnoreLoad is added to #behavior for class
 * method injection.
 *
 * Returns the number of methods added successfully. For each method that fails
 * to be added, \a failedToAddCallback (if provided) is invoked.
 */
unsigned ext_injectMethodsFromClass (Class srcClass, Class dstClass, ext_methodInjectionBehavior behavior, ext_failedMethodCallback failedToAddCallback);

/**
 * "Removes" any instance method matching \a methodName from \a aClass. This
 * removal can mean one of two things:
 *
 * @li If any superclass of \a aClass implements a method by the same name, the
 * implementation of the closest such superclass is used.
 * @li If no superclasses of \a aClass implement a method by the same name, the
 * method is replaced with a call to \c doesNotRecognizeSelector:. The \c
 * forwardInvocation: machinery is not invoked.
 */
void ext_removeMethod (Class aClass, SEL methodName);

/**
 * Iterates through the first \a count entries in \a methods and adds each one
 * to \a aClass, replacing any existing implementation.
 */
void ext_replaceMethods (Class aClass, Method *methods, unsigned count);

/**
 * Iterates through all instance and class methods of \a srcClass and adds each
 * one to \a dstClass, replacing any existing implementation.
 *
 * @note This ignores any \c +load method on \a srcClass. \a srcClass and \a
 * dstClass must not be metaclasses.
 */
void ext_replaceMethodsFromClass (Class srcClass, Class dstClass);

