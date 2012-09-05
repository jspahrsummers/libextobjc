//
//  NSMethodSignature+EXT.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-03-11.
//  Copyright (C) 2012 Justin Spahr-Summers.
//  Released under the MIT license.
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

	// start counting the NUL byte for strlcpy()
	stringLength++;

    char *encoding = calloc(stringLength, 1);
    strlcpy(encoding, [self methodReturnType], stringLength);

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

		size_t currentLength = strlen(encoding);
        strlcpy(encoding + currentLength, argType, stringLength - currentLength);
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

	stringLength++;

    char *encoding = calloc(stringLength, 1);
    strlcpy(encoding, [self methodReturnType], stringLength);

    for (NSUInteger i = 0;i < argumentCount;++i) {
        const char *argType = [self getArgumentTypeAtIndex:i];

		size_t currentLength = strlen(encoding);
        strlcpy(encoding + currentLength, argType, stringLength - currentLength);
    }

    // create an unused NSData object to autorelease the allocated string
    [NSData dataWithBytesNoCopy:encoding length:stringLength + 1 freeWhenDone:YES];

    return encoding;
}
@end
