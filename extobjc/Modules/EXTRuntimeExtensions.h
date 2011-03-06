//
//  EXTRuntimeExtensions.h
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-03-05.
//  Released into the public domain.
//

#import <objc/runtime.h>

/**
 * Iterates through the first \a count entries in \a methods and attempts to add
 * each one to \a aClass. If a method by the same name already exists on \a
 * aClass, it is \e not overridden. If \a checkSuperclasses is \c YES, and
 * a method by the same name already exists on any superclass of \a aClass, it
 * is not overridden.
 *
 * Returns the number of methods added successfully, or \c NO if there was
 * a conflict or an error occurred. Additionally, the first \a count entries in
 * methods are updated accordingly:
 *
 * @li The entries for any methods which were added successfully are set to \c
 * NULL.
 * @li The entries for any methods which failed to be added are left as-is.
 */
unsigned ext_addMethods (Class aClass, Method *methods, unsigned count, BOOL checkSuperclasses);

/**
 * Looks through the complete list of classes registered with the runtime and
 * finds all classes which are descendant from \a aClass. Returns \c
 * *subclassCount classes terminated by a \c NULL. You must \c free() the
 * returned array. If there are no subclasses of \a aClass, \c NULL is
 * returned.
 *
 * @note \a subclassCount may be \c NULL.
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
 * Returns the value of the instance variable named \a NAME from instance \a
 * OBJ. The instance variable must be of type \a TYPE, and is returned as such.
 *
 * @note \a OBJ is evaluated twice.
 *
 * @warning Depending on the platform, this may or may not work with aggregate
 * or floating-point types.
 */
#define ext_getIvarByName(OBJ, NAME, TYPE) \
	ext_getIvar((OBJ), class_getInstanceVariable(object_getClass((OBJ)), (NAME)), TYPE)

