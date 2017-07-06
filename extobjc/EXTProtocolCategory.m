//
//  EXTProtocolCategory.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 2010-11-13.
//  Copyright (C) 2012 Justin Spahr-Summers.
//  Released under the MIT license.
//

#import "EXTProtocolCategory.h"
#import "EXTRuntimeExtensions.h"
#import <pthread.h>
#import <stdlib.h>

/*
 * The implementation in this file is very similar in concept to that of
 * EXTConcreteProtocol, except that there is no inheritance between
 * EXTProtocolCategories, and methods are injected DESTRUCTIVELY (rather than
 * non-destructively in all cases).
 */

BOOL ext_addProtocolCategory (Protocol *protocol, Class containerClass) {
    return ext_loadSpecialProtocol(protocol, ^(Class class){
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
    });
}

void ext_loadProtocolCategory (Protocol *protocol) {
    ext_specialProtocolReadyForInjection(protocol);
}

