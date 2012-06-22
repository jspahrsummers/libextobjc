//
//  NSMethodSignature+EXT.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-03-11.
//  Released into the public domain.
//

#import "NSMethodSignature+EXT.h"

@implementation NSMethodSignature (EXTExtensions)
- (NSMethodSignature *)methodSignatureByInsertingType:(const char *)type atArgumentIndex:(NSUInteger)index {
    NSUInteger argumentCount = [self numberOfArguments];
    size_t typeLength = strlen(type);

    size_t stringLength = strlen([self methodReturnType]);
    for (NSUInteger i = 0;i < argumentCount + 1;++i) {
        NSUInteger realIndex;
        if (i == index) {
            stringLength += typeLength;
            continue;
        } else if (i > index) {
            realIndex = i - 1;
        } else {
            realIndex = i;
        }
            
        const char *argType = [self getArgumentTypeAtIndex:realIndex];
        stringLength += strlen(argType);
    }

    char *encoding = calloc(stringLength + 1, 1);
    strcpy(encoding, [self methodReturnType]);

    for (NSUInteger i = 0;i < argumentCount + 1;++i) {
        NSUInteger realIndex = i;
        const char *argType = NULL;

        if (i == index) {
            argType = type;     
        } else if (i > index) {
            realIndex = i - 1;
        }
        
        if (!argType)
            argType = [self getArgumentTypeAtIndex:realIndex];

        // LIVE ON THE EDGE!
        strcpy(encoding + strlen(encoding), argType);
    }
    
    NSMethodSignature *newSignature = [NSMethodSignature signatureWithObjCTypes:encoding];
    free(encoding);

    return newSignature;
}

- (const char *)typeEncoding {
    NSUInteger argumentCount = [self numberOfArguments];

    size_t stringLength = strlen([self methodReturnType]);
    for (NSUInteger i = 0;i < argumentCount;++i) {
        const char *argType = [self getArgumentTypeAtIndex:i];
        stringLength += strlen(argType);
    }

    char *encoding = calloc(stringLength + 1, 1);
    strcpy(encoding, [self methodReturnType]);

    for (NSUInteger i = 0;i < argumentCount;++i) {
        const char *argType = [self getArgumentTypeAtIndex:i];

        // LIVE ON THE EDGE!
        strcpy(encoding + strlen(encoding), argType);
    }

    // create an unused NSData object to autorelease the allocated string
    [NSData dataWithBytesNoCopy:encoding length:stringLength + 1 freeWhenDone:YES];

    return encoding;
}
@end
