//
//  EXTProtocolCategory.h
//  extobjc
//
//  Created by Justin Spahr-Summers on 2010-11-13.
//  Copyright (C) 2012 Justin Spahr-Summers.
//  Released under the MIT license.
//

#import <objc/runtime.h>
#import <stdio.h>
#import "metamacros.h"

/**
 * \@pcategoryinterface defines the interface for a category named \a CATEGORY on protocol \a
 * PROTOCOL. Protocol categories contain methods that are automatically applied
 * to any class that declares itself to conform to \a PROTOCOL. This macro
 * should be used in header files.
 *
 * @note This macro actually defines an interface against \c NSObject, meaning
 * that classes not inheriting from \c NSObject may cause compiler warnings
 * about not responding to the category's methods. Such warnings can be
 * disregarded, as the category will still be loaded normally.
 *
 * @warning Protocol categories function similarly to normal categories in that
 * they will overwrite any existing methods. Just like regular categories, the
 * order in which conflicting protocols overwrite each other is indeterminate.
 * These behaviors are even more dangerous in the case of protocols, where the
 * methods may be applied to many distinct classes. Use with care.
 */
#define pcategoryinterface(PROTOCOL, CATEGORY) \
    interface NSObject (CATEGORY)

/**
 * \@pcategoryimplementation defines the implementation for a category named \a CATEGORY on protocol \a
 * PROTOCOL. Protocol categories contain methods that are automatically applied
 * to any class that declares itself to conform to \a PROTOCOL. This macro
 * should be used in implementation files.
 *
 * To perform tasks when a protocol category is loaded, use the \c +initialize
 * method. This method in a protocol category is treated similarly to \c +load
 * in regular categories – it will be executed at most once per protocol
 * category, and is not added to any classes which receive the protocol
 * category's methods. Note, however, that the category's methods may not have
 * been added to all conforming classes at the time that \c +initialize is
 * invoked. If no class conforms to \a PROTOCOL, \c +initialize may never be
 * called.
 *
 * There is intentionally no supported way to inject an \c +initialize method
 * as part of a protocol category.
 *
 * @note You cannot access instance variables in a protocol category, except
 * through defined accessor methods.
 *
 * @warning You should not invoke methods against \c super in the implementation
 * of a concrete protocol, as the superclass may not be the type you expect (and
 * may not even inherit from \c NSObject).
 */
#define pcategoryimplementation(PROTOCOL, CATEGORY) \
    /*
     * create a class used to contain all the methods used in this category
     */ \
    interface PROTOCOL ## _ ## CATEGORY ## _MethodContainer : NSObject {} \
    @end \
    \
    @implementation PROTOCOL ## _ ## CATEGORY ## _MethodContainer \
    /*
     * when this class is loaded into the runtime, add the protocol category
     * into the list we have of them
     */ \
    + (void)load { \
        /*
         * passes the actual protocol as the first parameter, then this class as
         * the second
         */ \
        if (!ext_addProtocolCategory(objc_getProtocol(metamacro_stringify(PROTOCOL)), self)) \
            fprintf(stderr, "ERROR: Could not load protocol category %s (%s)\n", metamacro_stringify(PROTOCOL), # CATEGORY); \
    } \
    \
    /*
     * using the "constructor" function attribute, we can ensure that this
     * function is executed only AFTER all the Objective-C runtime setup (i.e.,
     * after all +load methods have been executed)
     */ \
    __attribute__((constructor)) \
    static void ext_ ## PROTOCOL ## _ ## CATEGORY ## _inject (void) { \
        /*
         * use this injection point to mark this protocol category as ready for
         * loading
         */ \
        ext_loadProtocolCategory(objc_getProtocol(metamacro_stringify(PROTOCOL))); \
    }

/*** implementation details follow ***/
BOOL ext_addProtocolCategory (Protocol *protocol, Class methodContainer);
void ext_loadProtocolCategory (Protocol *protocol);

