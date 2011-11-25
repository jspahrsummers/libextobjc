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

static void methodReplacementWithAdvice (ffi_cif *cif, void *result, void **args, void *userdata) {
    id self = *(__strong id *)args[0];
    SEL _cmd = *(SEL *)args[1];

    Class aspectContainer = (__bridge Class)userdata;
    Class selfClass = object_getClass(self);

    if (class_isMetaClass(selfClass)) {
        // if we're adding advice to a class method, use class methods on the
        // aspect container as well
        aspectContainer = object_getClass(aspectContainer);
    }

    ext_adviceOriginalMethodBlock originalMethod = ^{
        SEL originalSelector = originalSelectorForSelector(_cmd);
        IMP originalIMP = class_getMethodImplementation(selfClass, originalSelector);

        ffi_call(cif, FFI_FN(originalIMP), result, args);
    };

    Method advice = class_getInstanceMethod(aspectContainer, @selector(advise:));
    if (advice) {
        ext_adviceIMP adviceIMP = (ext_adviceIMP)method_getImplementation(advice);
        adviceIMP(self, _cmd, originalMethod);
    } else {
        originalMethod();
    }
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

static void ext_injectAspect (Class containerClass, Class class) {
    unsigned imethodCount = 0;
    Method *imethodList = class_copyMethodList(class, &imethodCount);

    for (unsigned i = 0;i < imethodCount;++i) {
        Method method = imethodList[i];
        ext_addAdviceToMethod(class, method, containerClass);
    }

    free(imethodList);
}

BOOL ext_addAspect (Protocol *protocol, Class methodContainer) {
    return ext_loadSpecialProtocol(protocol, ^(Class destinationClass){
        ext_injectAspect(methodContainer, destinationClass);
    });
}

void ext_loadAspect (Protocol *protocol) {
    ext_specialProtocolReadyForInjection(protocol);
}
