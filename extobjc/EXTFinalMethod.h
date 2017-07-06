//
//  EXTFinalMethod.h
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-03-02.
//  Copyright (C) 2012 Justin Spahr-Summers.
//  Released under the MIT license.
//

#import <objc/runtime.h>
#import "metamacros.h"

/**
 * \@final declares final methods for \a CLASS. Any methods declared in this block
 * cannot be overridden by subclasses. If \c DEBUG is defined and \c NDEBUG is
 * not defined, any overriding of final methods will abort the application at
 * startup; otherwise, the error is logged and execution continues using the
 * overridden method.
 *
 * Final method declarations must be followed by \c @endfinal. This macro
 * should only be used in an implementation file.
 *
 * @todo \c @property declarations are currently not supported within \c @final
 * blocks.
 */
#define final(CLASS) \
    protocol ext_ ## CLASS ## _FinalMethods; \
    @protocol ext_ ## CLASS ## _FinalMethodsFakeProtocol <ext_ ## CLASS ## _FinalMethods> \
    @end \
    \
    @interface CLASS (FinalMethodsProtocol) <ext_ ## CLASS ## _FinalMethodsFakeProtocol> \
    @end \
    \
    extern __unsafe_unretained Class ext_finalMethodsClass_; \
    extern __unsafe_unretained Protocol *ext_finalMethodsFakeProtocol_; \
    \
    __attribute__((constructor)) \
    static void ext_ ## CLASS ## _prepareFinalMethods (void) { \
        ext_finalMethodsClass_ = objc_getClass(# CLASS); \
        ext_finalMethodsFakeProtocol_ = @protocol(ext_ ## CLASS ## _FinalMethodsFakeProtocol); \
    } \
    \
    @protocol ext_ ## CLASS ## _FinalMethods

/**
 * Ends a set of final method declarations. This must be used instead of \c
 * @end.
 *
 * @note This macro should only be used in an implementation file.
 */
#define endfinal \
    end \
    \
    __attribute__((constructor)) \
    static void metamacro_concat(ext_checkFinalMethods_, __LINE__) (void) { \
        Class targetClass = ext_finalMethodsClass_; \
        \
        unsigned listCount = 0; \
        __unsafe_unretained Protocol **protocolList = protocol_copyProtocolList(ext_finalMethodsFakeProtocol_, &listCount); \
        \
        Protocol *finalMethodsProtocol = protocolList[0]; \
        free(protocolList); \
        \
        if (!ext_verifyFinalProtocolMethods(targetClass, finalMethodsProtocol)) { \
            ext_finalMethodsFailed(targetClass); \
        } \
    }

/*** implementation details follow ***/
BOOL ext_verifyFinalProtocolMethods (Class targetClass, Protocol *protocol);

// if this is a debug build...
#if defined(DEBUG) && !defined(NDEBUG)
    // abort if a final method is overridden
    #define ext_finalMethodsFailed(CLASS) \
        abort()
#else
    // otherwise, do nothing (the error message is printed in
    // ext_verifyFinalProtocolMethods)
    #define ext_finalMethodsFailed(CLASS)
#endif
