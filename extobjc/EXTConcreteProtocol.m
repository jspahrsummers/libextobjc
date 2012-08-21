//
//  EXTConcreteProtocol.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 2010-11-10.
//  Copyright (C) 2012 Justin Spahr-Summers.
//  Released under the MIT license.
//

#import "EXTConcreteProtocol.h"
#import "EXTRuntimeExtensions.h"
#import <pthread.h>
#import <stdlib.h>

static void ext_injectConcreteProtocol (Protocol *protocol, Class containerClass, Class class) {
    // get the full list of instance methods implemented by the concrete
    // protocol
    unsigned imethodCount = 0;
    Method *imethodList = class_copyMethodList(containerClass, &imethodCount);

    // get the full list of class methods implemented by the concrete
    // protocol
    unsigned cmethodCount = 0;
    Method *cmethodList = class_copyMethodList(object_getClass(containerClass), &cmethodCount);
            
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

BOOL ext_addConcreteProtocol (Protocol *protocol, Class containerClass) {
    return ext_loadSpecialProtocol(protocol, ^(Class destinationClass){
        ext_injectConcreteProtocol(protocol, containerClass, destinationClass);
    });
}

void ext_loadConcreteProtocol (Protocol *protocol) {
    ext_specialProtocolReadyForInjection(protocol);
}

