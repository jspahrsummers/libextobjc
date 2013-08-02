//
//  EXTPrivateMethod.h
//  extobjc
//
//  Created by Justin Spahr-Summers on 2012-06-26.
//  Copyright (C) 2012 Justin Spahr-Summers.
//  Released under the MIT license.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "metamacros.h"

/**
 * \@private declares methods or properties of the given \a CLASS to be private.
 * At application startup, if any of those methods conflict with superclass
 * methods, or are accidentally overridden by subclasses, an error will be
 * logged. If \c DEBUG is defined and \c NDEBUG is not defined, any method
 * conflicts will also abort the application.
 *
 * This macro should be used in implementation files. Any method or property
 * declarations may appear between \@private and \@end, just as with a protocol
 * or category. The method implementations should go into the main
 * implementation block for the class.
 */
#define private(CLASS) \
    protocol ext_ ## CLASS ## _PrivateMethods; \
    @protocol ext_ ## CLASS ## _PrivateMethodsFakeProtocol <ext_ ## CLASS ## _PrivateMethods> \
    @end \
    \
    @interface NSObject (CLASS ## _PrivateMethodsProtocol) <ext_ ## CLASS ## _PrivateMethodsFakeProtocol> \
    @end \
    \
    __attribute__((constructor)) \
    static void ext_ ## CLASS ## _validatePrivateMethods (void) { \
        Class targetClass = objc_getClass(# CLASS); \
        Protocol *fakeProtocol = @protocol(ext_ ## CLASS ## _PrivateMethodsFakeProtocol); \
        \
        unsigned listCount = 0; \
        __unsafe_unretained Protocol **protocolList = protocol_copyProtocolList(fakeProtocol, &listCount); \
        \
        Protocol *privateMethodsProtocol = protocolList[0]; \
        free(protocolList); \
        \
        if (!ext_validatePrivateMethodsOfClass(targetClass, privateMethodsProtocol)) { \
            ext_privateMethodsFailed(targetClass); \
        } \
    } \
    \
    @protocol ext_ ## CLASS ## _PrivateMethods \
    @required

/*** implementation details follow ***/
BOOL ext_validatePrivateMethodsOfClass (Class targetClass, Protocol *privateMethodsProtocol);

// if this is a debug build...
#if defined(DEBUG) && !defined(NDEBUG)
    // abort if private methods collide
    #define ext_privateMethodsFailed(CLASS) \
        abort()
#else
    #define ext_privateMethodsFailed(CLASS)
#endif
