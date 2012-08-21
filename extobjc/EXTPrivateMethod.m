//
//  EXTPrivateMethod.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 2012-06-26.
//  Copyright (C) 2012 Justin Spahr-Summers.
//  Released under the MIT license.
//

#import "EXTPrivateMethod.h"
#import "EXTRuntimeExtensions.h"
#import "EXTScope.h"

static BOOL ext_validateProtocolMethods (Class targetClass, Protocol *privateMethodsProtocol, BOOL instance) {
    __block unsigned protocolMethodCount = 0;
    struct objc_method_description *methodDescriptions = protocol_copyMethodDescriptionList(privateMethodsProtocol, YES, instance, &protocolMethodCount);
    if (!methodDescriptions) {
        return YES;
    }

    @onExit {
        free(methodDescriptions);
    };

    char methodPrefix;
    if (instance) {
        methodPrefix = '-';
    } else {
        methodPrefix = '+';
        targetClass = object_getClass(targetClass);
    }

    typedef void (^ValidationErrorBlock)(SEL);
    __block BOOL success = YES;

    void (^validateProtocolMethodsAgainstClass)(Class, BOOL, ValidationErrorBlock) = ^(Class testClass, BOOL removeFailures, ValidationErrorBlock errorBlock){
        unsigned classMethodCount = 0;
        Method *classMethodList = class_copyMethodList(testClass, &classMethodCount);
        if (!classMethodList)
            return;

        @onExit {
            free(classMethodList);
        };

        for (unsigned classMethodIndex = 0; classMethodIndex < classMethodCount; ++classMethodIndex) {
            SEL selector = method_getName(classMethodList[classMethodIndex]);

            for (unsigned protocolMethodIndex = 0; protocolMethodIndex < protocolMethodCount; ++protocolMethodIndex) {
                if (methodDescriptions[protocolMethodIndex].name != selector)
                    continue;

                errorBlock(selector);

                if (removeFailures) {
                    // remove this selector from the method description list (so
                    // we don't complain about it more than once)
                    unsigned remainingProtocolMethods = protocolMethodCount - protocolMethodIndex - 1;
                    memmove(methodDescriptions + protocolMethodIndex, methodDescriptions + protocolMethodIndex + 1, sizeof(*methodDescriptions) * remainingProtocolMethods);
                    --protocolMethodCount;
                }

                success = NO;
                break;
            }
        }
    };

    // check to see if we accidentally overrode any superclasses
    Class superclass = targetClass;

    while ((superclass = class_getSuperclass(superclass))) {
        validateProtocolMethodsAgainstClass(superclass, YES, ^(SEL selector){
            fprintf(stderr, "ERROR: Private method %c%s in %s overrides a method by the same name in %s\n",
                methodPrefix, sel_getName(selector), class_getName(targetClass), class_getName(superclass));
        });
    }

    // check to see if any subclasses accidentally overrode us
    unsigned subclassCount = 0;
    Class *subclassList = ext_copySubclassList(targetClass, &subclassCount);

    for (unsigned subclassIndex = 0; subclassIndex < subclassCount; ++subclassIndex) {
        Class subclass = subclassList[subclassIndex];

        validateProtocolMethodsAgainstClass(subclass, NO, ^(SEL selector){
            fprintf(stderr, "ERROR: Method %c%s in %s overrides a private method by the same name in %s\n",
                methodPrefix, sel_getName(selector), class_getName(subclass), class_getName(targetClass));
        });
    }

    return success;
}

BOOL ext_validatePrivateMethodsOfClass (Class targetClass, Protocol *privateMethodsProtocol) {
    return ext_validateProtocolMethods(targetClass, privateMethodsProtocol, YES) && ext_validateProtocolMethods(targetClass, privateMethodsProtocol, NO);
}
