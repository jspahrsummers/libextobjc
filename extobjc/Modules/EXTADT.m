//
//  EXTADT.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 19.06.12.
//  Released into the public domain.
//

#import "EXTADT.h"

NSString *EXTADT_NSStringFromBytes (const void *bytes, const char *encoding) {
    switch (*encoding) {
        case 'c': return @(*(char *)bytes).description;
        case 'C': return @(*(unsigned char *)bytes).description;
        case 'i': return @(*(int *)bytes).description;
        case 'I': return @(*(unsigned int *)bytes).description;
        case 's': return @(*(short *)bytes).description;
        case 'S': return @(*(unsigned short *)bytes).description;
        case 'l': return @(*(long *)bytes).description;
        case 'L': return @(*(unsigned long *)bytes).description;
        case 'q': return @(*(long long *)bytes).description;
        case 'Q': return @(*(unsigned long long *)bytes).description;
        case 'f': return @(*(float *)bytes).description;
        case 'd': return @(*(double *)bytes).description;
        case 'B': return @(*(_Bool *)bytes).description;
        case 'v': return @"(void)";
        case '*': return [NSString stringWithFormat:@"\"%s\"", bytes];

        case '@':
        case '#': {
            id obj = *(__unsafe_unretained id *)bytes;
            if (obj)
                return [obj description];
            else
                return @"(nil)";
        }

        case '?':
        case '^': {
            const void *ptr = *(const void **)bytes;
            if (ptr)
                return [NSString stringWithFormat:@"%p", ptr];
            else
                return @"(null)";
        }

        default:
            return [[NSValue valueWithBytes:bytes objCType:encoding] description];
    }
}
