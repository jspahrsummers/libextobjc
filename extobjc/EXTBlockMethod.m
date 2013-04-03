//
//  EXTBlockMethod.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-03-11.
//  Copyright (C) 2012 Justin Spahr-Summers.
//  Released under the MIT license.
//

#import "EXTBlockMethod.h"
#import "NSMethodSignature+EXT.h"
#import <ctype.h>
#import <libkern/OSAtomic.h>
#import <stdio.h>
#import <string.h>

/*
 * The following block-related definitions are taken from:
 * http://clang.llvm.org/docs/Block-ABI-Apple.txt
 */
typedef struct {
    unsigned long int reserved;
    unsigned long int size;

    void (*copy_helper)(void *dst, void *src);
    void (*dispose_helper)(void *src);

    const char *signature;
} ext_blockDescriptor_t;

typedef struct {
    void *isa;
    int flags;
    int reserved; 

    // the first argument will be the block structure, followed by any actual
    // arguments to the block
    void (*invoke)(void *, ...);

    ext_blockDescriptor_t *descriptor;

    // variables begin here
} ext_block_t;

typedef struct ext_blockVariable_t {
    void *isa;
    struct ext_blockVariable_t *forwarding;
    int flags;
    int size;

    // these may or may not be present... flags will be 0 if they are NOT
    // present
    void (*byref_keep)(void  *dst, void *src);
    void (*byref_dispose)(void *);

    // variable data begins here
} ext_blockVariable_t;

enum {
    BLOCK_HAS_COPY_DISPOSE =  (1 << 25),
    BLOCK_HAS_CTOR =          (1 << 26),
    BLOCK_IS_GLOBAL =         (1 << 28),
    BLOCK_HAS_STRET =         (1 << 29),
    BLOCK_HAS_SIGNATURE =     (1 << 30), 
};

typedef struct { int i; } *empty_struct_ptr_t;
typedef union { int i; } *empty_union_ptr_t;

BOOL ext_addBlockMethod (Class aClass, SEL name, id block, const char *types) {
    block = [block copy];

    BOOL success = class_addMethod(
        aClass,
        name,
        imp_implementationWithBlock(block),
        types
    );

    if (!success) {
        return NO;
    }
    
    objc_setAssociatedObject(aClass, name, block, OBJC_ASSOCIATION_COPY);
    return YES;
}

char *ext_copyBlockTypeEncoding (id block) {
    ext_block_t *blockInnards = (__bridge ext_block_t *)block;

    if (!(blockInnards->flags & BLOCK_HAS_SIGNATURE))
        return NULL;

    const char *blockSignature = blockInnards->descriptor->signature;
    if (!blockSignature)
        return NULL;
    
    size_t blockSignatureLen = strlen(blockSignature);
    char * restrict sanitized = malloc(blockSignatureLen);
    if (!sanitized)
        return NULL;

    size_t sanitizedPos = 0;
    
    @try {
        while (*blockSignature != '\0') {
            const char *next = NSGetSizeAndAlignment(blockSignature, NULL, NULL);
            if (!next)
                break;

            // copy the valid part of the type encoding into the sanitized string
            strncpy(sanitized + sanitizedPos, blockSignature, next - blockSignature);
            sanitizedPos += (next - blockSignature);

            // and skip over any (invalid) digits
            while (isdigit(*next))
                ++next;

            blockSignature = next;
        }
    } @catch (NSException *ex) {
        // a thrown exception almost certainly means that this type encoding
        // is invalid
        free(sanitized);
        return NULL;
    }

    if (sanitizedPos == 0) {
        // a zero-length encoding won't work, just return NULL
        free(sanitized);
        return NULL;
    }

    sanitized[sanitizedPos] = '\0';
    return sanitized;
}

void ext_replaceBlockMethod (Class aClass, SEL name, id block, const char *types) {
    block = [block copy];

    class_replaceMethod(
        aClass,
        name,
        imp_implementationWithBlock(block),
        types
    );

    objc_setAssociatedObject(aClass, name, block, OBJC_ASSOCIATION_COPY);
}

void ext_synthesizeBlockProperty (const char *type, ext_propertyMemoryManagementPolicy memoryManagementPolicy, BOOL atomic, __autoreleasing ext_blockGetter *getter, __autoreleasing ext_blockSetter *setter) {
    // skip attributes in the provided type encoding
    while (
        *type == 'r' ||
        *type == 'n' ||
        *type == 'N' ||
        *type == 'o' ||
        *type == 'O' ||
        *type == 'R' ||
        *type == 'V'
    ) {
        ++type;
    }

    #define SET_ATOMIC_VAR(VARTYPE, CASTYPE) \
        VARTYPE existingValue; \
        \
        for (;;) { \
            existingValue = backingVar; \
            if (OSAtomicCompareAndSwap ## CASTYPE ## Barrier(existingValue, newValue, (VARTYPE volatile *)&backingVar)) { \
                break; \
            } \
        } \
    
    #define SYNTHESIZE_COMPATIBLE_PRIMITIVE(RETTYPE, VARTYPE, CASTYPE) \
        do { \
            if (atomic) { \
                __block VARTYPE volatile backingVar = 0; \
                \
                id localGetter = ^(id self){ \
                    return (RETTYPE)backingVar; \
                }; \
                \
                id localSetter = ^(id self, RETTYPE newRealValue){ \
                    VARTYPE newValue = (VARTYPE)newRealValue; \
                    SET_ATOMIC_VAR(VARTYPE, CASTYPE); \
                }; \
                \
                *getter = [localGetter copy]; \
                *setter = [localSetter copy]; \
            } else { \
                __block RETTYPE backingVar = 0; \
                \
                id localGetter = ^(id self){ \
                    return backingVar; \
                }; \
                \
                id localSetter = ^(id self, RETTYPE newRealValue){ \
                    backingVar = newRealValue; \
                }; \
                \
                *getter = [localGetter copy]; \
                *setter = [localSetter copy]; \
            } \
        } while (0)
    
    #define SYNTHESIZE_PRIMITIVE(RETTYPE, VARTYPE, CASTYPE) \
        do { \
            if (atomic) { \
                __block VARTYPE volatile backingVar = 0; \
                \
                id localGetter = ^(id self){ \
                    union { \
                        VARTYPE backing; \
                        RETTYPE real; \
                    } u; \
                    \
                    u.backing = backingVar; \
                    return u.real; \
                }; \
                \
                id localSetter = ^(id self, RETTYPE newRealValue){ \
                    union { \
                        VARTYPE backing; \
                        RETTYPE real; \
                    } u; \
                    \
                    u.backing = 0; \
                    u.real = newRealValue; \
                    VARTYPE newValue = u.backing; \
                    \
                    SET_ATOMIC_VAR(VARTYPE, CASTYPE); \
                }; \
                \
                *getter = [localGetter copy]; \
                *setter = [localSetter copy]; \
            } else { \
                __block RETTYPE backingVar = 0; \
                \
                id localGetter = ^(id self){ \
                    return backingVar; \
                }; \
                \
                id localSetter = ^(id self, RETTYPE newRealValue){ \
                    backingVar = newRealValue; \
                }; \
                \
                *getter = [localGetter copy]; \
                *setter = [localSetter copy]; \
            } \
        } while (0)

    #define SYNTHESIZE_OBJECT(POLICY) \
        do { \
            __block POLICY volatile id backingVar = nil; \
            __block OSSpinLock spinLock = 0; \
            \
            id localGetter = ^(id self){ \
                OSSpinLockLock(&spinLock); \
                id value = backingVar; \
                OSSpinLockUnlock(&spinLock); \
            \
                return value; \
            }; \
            \
            id localSetter = ^(id self, id newValue){ \
                if (memoryManagementPolicy == ext_propertyMemoryManagementPolicyCopy) { \
                    newValue = [newValue copy]; \
                } \
                \
                OSSpinLockLock(&spinLock); \
                backingVar = newValue; \
                OSSpinLockUnlock(&spinLock); \
            }; \
            \
            *getter = [localGetter copy]; \
            *setter = [localSetter copy]; \
        } while (0)

    switch (*type) {
    case 'c':
        SYNTHESIZE_PRIMITIVE(char, int, Int);
        break;
    
    case 'i':
        SYNTHESIZE_COMPATIBLE_PRIMITIVE(int, int, Int);
        break;
    
    case 's':
        SYNTHESIZE_PRIMITIVE(short, int, Int);
        break;
    
    case 'l':
        SYNTHESIZE_COMPATIBLE_PRIMITIVE(long, long, Long);
        break;
    
    case 'q':
        SYNTHESIZE_PRIMITIVE(long long, int64_t, 64);
        break;
    
    case 'C':
        SYNTHESIZE_PRIMITIVE(unsigned char, int, Int);
        break;
    
    case 'I':
        SYNTHESIZE_COMPATIBLE_PRIMITIVE(unsigned int, int, Int);
        break;
    
    case 'S':
        SYNTHESIZE_PRIMITIVE(unsigned short, int, Int);
        break;
    
    case 'L':
        SYNTHESIZE_COMPATIBLE_PRIMITIVE(unsigned long, long, Long);
        break;
    
    case 'Q':
        SYNTHESIZE_PRIMITIVE(unsigned long long, int64_t, 64);
        break;
    
    case 'f':
        if (sizeof(float) > sizeof(int32_t)) {
            SYNTHESIZE_PRIMITIVE(float, int64_t, 64);
        } else {
            SYNTHESIZE_PRIMITIVE(float, int32_t, 32);
        }

        break;
    
    case 'd':
        SYNTHESIZE_PRIMITIVE(double, int64_t, 64);
        break;
    
    case 'B':
        SYNTHESIZE_PRIMITIVE(_Bool, int, Int);
        break;
    
    case '*':
        SYNTHESIZE_COMPATIBLE_PRIMITIVE(char *, void *, Ptr);
        break;
    
    // all the logic around object memory management isn't strictly necessary
    // for class objects, but it's an easy way to avoid reimplementing it all
    case '#':
    case '@':
        if (atomic) {
            if (memoryManagementPolicy == ext_propertyMemoryManagementPolicyAssign) {
                SYNTHESIZE_OBJECT(__unsafe_unretained);
            } else {
                SYNTHESIZE_OBJECT(__strong);
            }
        } else {
            #define OSSpinLock(...)
            #define OSSpinUnlock(...)

            if (memoryManagementPolicy == ext_propertyMemoryManagementPolicyAssign) {
                SYNTHESIZE_OBJECT(__unsafe_unretained);
            } else {
                SYNTHESIZE_OBJECT(__strong);
            }

            #undef OSSpinLock
            #undef OSSpinUnlock
        }
        
        break;
    
    case ':':
        SYNTHESIZE_COMPATIBLE_PRIMITIVE(SEL, void *, Ptr);
        break;
    
    case '[':
        NSLog(@"Cannot synthesize property for array with type code \"%s\"", type);
        return;
    
    case 'b':
        NSLog(@"Cannot synthesize property for bitfield with type code \"%s\"", type);
        return;
    
    case '{':
        NSLog(@"Cannot synthesize property for struct with type code \"%s\"", type);
        return;
        
    case '(':
        NSLog(@"Cannot synthesize property for union with type code \"%s\"", type);
        return;
    
    case '^':
        switch (type[1]) {
        case 'c':
        case 'C':
            SYNTHESIZE_COMPATIBLE_PRIMITIVE(char *, void *, Ptr);
            break;
        
        case 'i':
        case 'I':
            SYNTHESIZE_COMPATIBLE_PRIMITIVE(int *, void *, Ptr);
            break;
        
        case 's':
        case 'S':
            SYNTHESIZE_COMPATIBLE_PRIMITIVE(short *, void *, Ptr);
            break;
        
        case 'l':
        case 'L':
            SYNTHESIZE_COMPATIBLE_PRIMITIVE(long *, void *, Ptr);
            break;
        
        case 'q':
        case 'Q':
            SYNTHESIZE_COMPATIBLE_PRIMITIVE(long long *, void *, Ptr);
            break;
        
        case 'f':
            SYNTHESIZE_COMPATIBLE_PRIMITIVE(float *, void *, Ptr);
            break;
        
        case 'd':
            SYNTHESIZE_COMPATIBLE_PRIMITIVE(double *, void *, Ptr);
            break;
        
        case 'B':
            SYNTHESIZE_COMPATIBLE_PRIMITIVE(_Bool *, void *, Ptr);
            break;
        
        case 'v':
            SYNTHESIZE_COMPATIBLE_PRIMITIVE(void *, void *, Ptr);
            break;
        
        case '*':
        case '@':
        case '#':
        case '^':
        case '[':
            SYNTHESIZE_COMPATIBLE_PRIMITIVE(void **, void *, Ptr);
            break;
        
        case ':':
            SYNTHESIZE_COMPATIBLE_PRIMITIVE(SEL *, void *, Ptr);
            break;
        
        case '{':
            SYNTHESIZE_COMPATIBLE_PRIMITIVE(empty_struct_ptr_t, void *, Ptr);
            break;
        
        case '(':
            SYNTHESIZE_COMPATIBLE_PRIMITIVE(empty_union_ptr_t, void *, Ptr);
            break;

        case '?':
            SYNTHESIZE_COMPATIBLE_PRIMITIVE(IMP *, void *, Ptr);
            break;
        
        case 'b':
        default:
            NSLog(@"Cannot synthesize property for unknown pointer type with type code \"%s\"", type);
            return;
        }
        
        break;
    
    case '?':
        // this is PROBABLY a function pointer, but the documentation
        // leaves room open for uncertainty, so at least log a message
        NSLog(@"Assuming type code \"%s\" is a function pointer", type);

        // using a backing variable of void * would be unsafe, since function
        // pointers and pointers may be different sizes
        SYNTHESIZE_PRIMITIVE(IMP, int64_t, 64);
        break;
        
    default:
        NSLog(@"Unexpected type code \"%s\", cannot synthesize property", type);
    }

    #undef SET_ATOMIC_VAR
    #undef SYNTHESIZE_PRIMITIVE
    #undef SYNTHESIZE_COMPATIBLE_PRIMITIVE
}

