//
//  EXTFinalMethod.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-03-02.
//  Copyright (C) 2012 Justin Spahr-Summers.
//  Released under the MIT license.
//

#import "EXTFinalMethod.h"
#import "EXTRuntimeExtensions.h"
#import <stdio.h>

Class ext_finalMethodsClass_ = nil;
Protocol *ext_finalMethodsFakeProtocol_ = NULL;

static
BOOL ext_verifyProtocolMethodsAgainstSubclasses (Protocol *protocol, Class targetClass, Class *subclasses, unsigned subclassCount, BOOL instanceMethods) {
    unsigned methodCount = 0;
    struct objc_method_description *methods = protocol_copyMethodDescriptionList(
        protocol,
        YES,
        instanceMethods,
        &methodCount
    );

    BOOL success = YES;
    for (unsigned subclassIndex = 0;subclassIndex < subclassCount;++subclassIndex) {
        Class subclass = subclasses[subclassIndex];
        if (!instanceMethods)
            subclass = object_getClass(subclass);

        unsigned subclassMethodCount = 0;
        Method *subclassMethods = class_copyMethodList(subclass, &subclassMethodCount);
        
        for (unsigned subclassMethodIndex = 0;subclassMethodIndex < subclassMethodCount;++subclassMethodIndex) {
            Method subclassMethod = subclassMethods[subclassMethodIndex];

            for (unsigned methodIndex = 0;methodIndex < methodCount;++methodIndex) {
                SEL name = methods[methodIndex].name;

                if (method_getName(subclassMethod) == name) {
                    const char *selectorName = sel_getName(name);
                    fprintf(stderr, "ERROR: Method %c%s in %s overrides final method by the same name in %s\n", (instanceMethods ? '-' : '+'), selectorName, class_getName(subclass), class_getName(targetClass));
                    success = NO;
                    break;
                }
            }
        }

        free(subclassMethods);
    }

    free(methods);
    return success;
}

BOOL ext_verifyFinalProtocolMethods (Class targetClass, Protocol *protocol) {
    unsigned subclassCount = 0;
    Class *subclasses = ext_copySubclassList(targetClass, &subclassCount);
    
    BOOL success = YES;

    // instance methods
    success &= ext_verifyProtocolMethodsAgainstSubclasses(
        protocol,
        targetClass,
        subclasses,
        subclassCount,
        YES
    );

    // class methods
    success &= ext_verifyProtocolMethodsAgainstSubclasses(
        protocol,
        targetClass,
        subclasses,
        subclassCount,
        NO
    );

    free(subclasses);
    return success;
}

