//
//  EXTRuntimeExtensions.h
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-03-05.
//  Released into the public domain.
//

#import <objc/runtime.h>

/**
 * Looks through the complete list of classes registered with the runtime and
 * finds all classes which are descendant from \a targetClass. Returns \c
 * *subclassCount classes terminated by a \c NULL. You must \c free() the
 * returned array. If there are no subclasses of \a targetClass, \c NULL is
 * returned.
 *
 * @note \a subclassCount may be \c NULL.
 */
Class *ext_copySubclassList (Class targetClass, unsigned *subclassCount);

