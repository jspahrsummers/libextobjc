//
//  EXTPrivateMethod.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-03-02.
//  Released into the public domain.
//

#import "EXTPrivateMethod.h"
#import "EXTRuntimeExtensions.h"
#import <string.h>

Class ext_privateMethodsClass_ = nil;
Protocol *ext_privateMethodsFakeProtocol_ = NULL;

static
id ext_removedMethodCalled (id self, SEL _cmd, ...) {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

static
BOOL ext_copyProtocolMethodsToClass (Protocol *protocol, Class srcClass, Class dstClass, BOOL instanceMethods) {
    unsigned methodCount = 0;
    struct objc_method_description *methods = protocol_copyMethodDescriptionList(
        protocol,
        YES,
        instanceMethods,
        &methodCount
    );

    BOOL success = YES;
    for (unsigned methodIndex = 0;methodIndex < methodCount;++methodIndex) {
        SEL name = methods[methodIndex].name;
        const char *selectorName = sel_getName(name);

        Method foundMethod = ext_getImmediateInstanceMethod(srcClass, name);
        if (!foundMethod) {
            fprintf(stderr, "ERROR: Method %c%s not found on class %s\n", (instanceMethods ? '-' : '+'), selectorName, class_getName(srcClass));
            success = NO;
            continue;
        }

        // TODO: keep track of methods injected like this so we can check
        // against an array, rather than a function address -- we can then
        // restore ext_removeMethod(), which has more reasonable behavior
        // anyways

        Method originalMethod = ext_getImmediateInstanceMethod(dstClass, name);
        if (originalMethod && method_getImplementation(originalMethod) != (IMP)&ext_removedMethodCalled) {
            fprintf(stderr, "ERROR: Method %c%s already exists on class %s\n", (instanceMethods ? '-' : '+'), selectorName, class_getName(dstClass));
            success = NO;
            continue;
        }
        
        class_replaceMethod(dstClass, name, method_getImplementation(foundMethod), method_getTypeEncoding(foundMethod));
        method_setImplementation(foundMethod, (IMP)&ext_removedMethodCalled);
    //  ext_removeMethod(srcClass, name);
    }

    free(methods);
    return success;
}

BOOL ext_makeProtocolMethodsPrivate (Class targetClass, Protocol *protocol) {
    Class superclass = class_getSuperclass(targetClass);
    if (!superclass) {
        fprintf(stderr, "ERROR: Cannot make methods on class %s private without a superclass\n", class_getName(targetClass));
        return NO;
    }

    BOOL success = YES;

    // instance methods
    success &= ext_copyProtocolMethodsToClass(
        protocol,
        targetClass,
        superclass,
        YES
    );

    // class methods
    success &= ext_copyProtocolMethodsToClass(
        protocol,
        object_getClass(targetClass),
        object_getClass(superclass),
        NO  
    );

    return success;
}

