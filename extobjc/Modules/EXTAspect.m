//
//  EXTAspect.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 24.11.11.
//  Released into the public domain.
//

#import "EXTAspect.h"
#import "EXTRuntimeExtensions.h"
#import "ffi.h"
#import <objc/runtime.h>

typedef void (^ext_adviceOriginalMethodBlock)(void);
typedef void (*ext_adviceIMP)(id, SEL, ext_adviceOriginalMethodBlock);

static SEL originalSelectorForSelector (SEL selector) {
    NSString *methodName = NSStringFromSelector(selector);
    NSString *originalMethodName = [methodName stringByAppendingString:@"_unadvised_"];
    return NSSelectorFromString(originalMethodName);
}

static SEL specificAdviceSelectorForSelector (SEL selector) {
    const char *methodName = sel_getName(selector);
    size_t methodNameLen = strlen(methodName);
    NSString *specificMethodName;

    if (methodName[methodNameLen - 1] == ':')
        specificMethodName = [NSString stringWithFormat:@"advise:%s", methodName];
    else {
        char firstLetter = (char)toupper(methodName[0]);
        ++methodName;
        specificMethodName = [NSString stringWithFormat:@"advise%c%s:", firstLetter, methodName];
    }

    return NSSelectorFromString(specificMethodName);
}

static void methodReplacementWithAdvice (ffi_cif *cif, void *result, void **args, void *userdata) {
    id self = *(__strong id *)args[0];
    SEL _cmd = *(SEL *)args[1];

    Class aspectContainer = (__bridge Class)userdata;
    Class selfClass = object_getClass(self);

    ext_adviceOriginalMethodBlock originalMethod = ^{
        SEL originalSelector = originalSelectorForSelector(_cmd);
        IMP originalIMP = class_getMethodImplementation(selfClass, originalSelector);

        ffi_call(cif, FFI_FN(originalIMP), result, args);
    };

    SEL specificAdviceSelector = specificAdviceSelectorForSelector(_cmd);
    Method specificAdvice = class_getInstanceMethod(aspectContainer, specificAdviceSelector);
    if (specificAdvice) {
        ffi_cif adviceCIF;

        // the advice method should have no return value
        ffi_type *returnType = &ffi_type_void;

        // the advice method has the same arguments as the original method, plus
        // an initial block pointer
        unsigned numberOfArguments = cif->nargs + 1;

        ffi_type *argTypes[numberOfArguments];

        // insert the block pointer type between after '_cmd' and before the
        // argument list
        memcpy(argTypes, cif->arg_types, sizeof(*argTypes) * 2);
        argTypes[2] = &ffi_type_pointer;

        if (numberOfArguments > 3)
            memcpy(argTypes + 3, cif->arg_types + 2, sizeof(*argTypes) * (numberOfArguments - 3));

        ffi_prep_cif(&adviceCIF, FFI_DEFAULT_ABI, numberOfArguments, returnType, argTypes);

        // insert block pointer in the argument list
        void *innerArgs[numberOfArguments];

        memcpy(innerArgs, args, sizeof(*innerArgs) * 2);

        void *blockPtr = (__bridge void *)originalMethod;
        innerArgs[2] = &blockPtr;

        if (numberOfArguments > 3)
            memcpy(innerArgs + 3, args + 2, sizeof(*innerArgs) * (numberOfArguments - 3));

        IMP adviceIMP = method_getImplementation(specificAdvice);

        ffi_call(&adviceCIF, FFI_FN(adviceIMP), NULL, innerArgs);

        return;
    }

    Method universalAdvice = class_getInstanceMethod(aspectContainer, @selector(advise:));
    if (universalAdvice) {
        ext_adviceIMP adviceIMP = (ext_adviceIMP)method_getImplementation(universalAdvice);
        adviceIMP(self, _cmd, originalMethod);
        return;
    }

    originalMethod();
}

static ffi_type *ext_FFITypeForEncoding (const char *typeEncoding) {
    switch (*typeEncoding) {
    case 'c':
        return &ffi_type_schar;

    case 'C':
        return &ffi_type_uchar;

    case 'i':
        return &ffi_type_sint;

    case 'I':
        return &ffi_type_uint;

    case 's':
        return &ffi_type_sshort;

    case 'S':
        return &ffi_type_ushort;

    case 'l':
        return &ffi_type_slong;

    case 'L':
        return &ffi_type_ulong;

    case 'q':
        assert(sizeof(long long) == 8);
        return &ffi_type_sint64;

    case 'Q':
        assert(sizeof(unsigned long long) == 8);
        return &ffi_type_uint64;

    case 'f':
        return &ffi_type_float;

    case 'd':
        return &ffi_type_double;

    case 'B':
        // assuming that _Bool is compatible with (or promoted to) int
        return &ffi_type_sint;

    case 'v':
        return &ffi_type_void;

    case '*':
    case '@':
    case '#':
    case ':':
    case '^':
    case '?':
        return &ffi_type_pointer;

    default:
        NSLog(@"Unrecognized type in \"%s\"", typeEncoding);
        return NULL;
    }
}

static void ext_addAdviceToMethod (Class class, Method method, Class containerClass) {
    SEL selector = method_getName(method);

    /*
     * All memory allocations below _intentionally_ leak memory. These
     * structures need to stick around for as long as the FFI closure will
     * be used, and, since we're installing a new method on a class, we're
     * operating under the assumption that it could be used anytime during
     * the lifetime of the application. There would be no appropriate time
     * to free this memory.
     */
    
    // argument types for testing
    unsigned argumentCount = method_getNumberOfArguments(method);
    ffi_type **argTypes = malloc(sizeof(*argTypes) * argumentCount);
    if (!argTypes) {
        fprintf(stderr, "ERROR: Could not allocate space for %u arguments\n", argumentCount);
        return;
    }

    ffi_type *returnType = NULL;
    const char *typeString = method_getTypeEncoding(method);
    unsigned typeIndex = 0;

    while (typeString) {
        // skip over numbers
        while (isdigit(*typeString))
            ++typeString;

        if (*typeString == '\0')
            break;

        ffi_type *type = ext_FFITypeForEncoding(typeString);

        // if this is the first type, it's describing the return value
        if (typeIndex == 0) {
            returnType = type;
        } else {
            assert(typeIndex - 1 < argumentCount);
            argTypes[typeIndex - 1] = type;
        }

        typeString = NSGetSizeAndAlignment(typeString, NULL, NULL);
        ++typeIndex;
    }

    ffi_cif *methodCIF = malloc(sizeof(*methodCIF));
    if (!methodCIF) {
        fprintf(stderr, "ERROR: Could not allocate new FFI CIF\n");
        return;
    }

    ffi_prep_cif(methodCIF, FFI_DEFAULT_ABI, argumentCount, returnType, argTypes);

    SEL movedSelector = originalSelectorForSelector(selector);
    class_addMethod(class, movedSelector, method_getImplementation(method), method_getTypeEncoding(method));

    void *replacementIMP = NULL;
    ffi_closure *closure = ffi_closure_alloc(sizeof(ffi_closure), &replacementIMP);

    ffi_prep_closure_loc(closure, methodCIF, &methodReplacementWithAdvice, (__bridge void *)containerClass, replacementIMP);
    method_setImplementation(method, (IMP)replacementIMP);
}

static void ext_injectAspect (Class containerInstanceClass, Class instanceClass) {
    // reused for instance and class method injection
    void (^injectFromClassIntoClass)(Class, Class) = ^(Class containerClass, Class class){
        unsigned methodCount = 0;
        Method *methodList = class_copyMethodList(class, &methodCount);

        BOOL hasUniversalAdvice = (class_getInstanceMethod(containerClass, @selector(advise:)) != NULL);

        for (unsigned i = 0;i < methodCount;++i) {
            Method method = methodList[i];
            SEL selector = method_getName(method);
            BOOL hasSpecificAdvice = (class_getInstanceMethod(containerClass, specificAdviceSelectorForSelector(selector)) != NULL);

            if (hasUniversalAdvice || hasSpecificAdvice)
                ext_addAdviceToMethod(class, method, containerClass);
        }

        free(methodList);
    };

    // instance methods
    injectFromClassIntoClass(containerInstanceClass, instanceClass);

    // class methods
    injectFromClassIntoClass(object_getClass(containerInstanceClass), object_getClass(instanceClass));
}

BOOL ext_addAspect (Protocol *protocol, Class methodContainer) {
    return ext_loadSpecialProtocol(protocol, ^(Class destinationClass){
        ext_injectAspect(methodContainer, destinationClass);
    });
}

void ext_loadAspect (Protocol *protocol) {
    ext_specialProtocolReadyForInjection(protocol);
}
