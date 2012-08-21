//
//  NSInvocation+EXT.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-03-11.
//  Copyright (C) 2012 Justin Spahr-Summers.
//  Released under the MIT license.
//

#import "NSInvocation+EXT.h"

typedef struct { int i; } *empty_struct_ptr_t;
typedef union { int i; } *empty_union_ptr_t;

@implementation NSInvocation (EXTExtensions)
- (BOOL)setArgumentsFromArgumentList:(va_list)args {
    NSMethodSignature *signature = [self methodSignature];
    NSUInteger count = [signature numberOfArguments];
    for (NSUInteger i = 2;i < count;++i) {
        const char *type = [signature getArgumentTypeAtIndex:i];
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
        
        switch (*type) {
        case 'c':
            {
                char val = (char)va_arg(args, int);
                [self setArgument:&val atIndex:i];
            }
            
            break;
        
        case 'i':
            {
                int val = va_arg(args, int);
                [self setArgument:&val atIndex:i];
            }
            
            break;
        
        case 's':
            {
                short val = (short)va_arg(args, int);
                [self setArgument:&val atIndex:i];
            }
            
            break;
        
        case 'l':
            {
                long val = va_arg(args, long);
                [self setArgument:&val atIndex:i];
            }
            
            break;
        
        case 'q':
            {
                long long val = va_arg(args, long long);
                [self setArgument:&val atIndex:i];
            }
            
            break;
        
        case 'C':
            {
                unsigned char val = (unsigned char)va_arg(args, unsigned int);
                [self setArgument:&val atIndex:i];
            }
            
            break;
        
        case 'I':
            {
                unsigned int val = va_arg(args, unsigned int);
                [self setArgument:&val atIndex:i];
            }
            
            break;
        
        case 'S':
            {
                unsigned short val = (unsigned short)va_arg(args, unsigned int);
                [self setArgument:&val atIndex:i];
            }
            
            break;
        
        case 'L':
            {
                unsigned long val = va_arg(args, unsigned long);
                [self setArgument:&val atIndex:i];
            }
            
            break;
        
        case 'Q':
            {
                unsigned long long val = va_arg(args, unsigned long long);
                [self setArgument:&val atIndex:i];
            }
            
            break;
        
        case 'f':
            {
                float val = (float)va_arg(args, double);
                [self setArgument:&val atIndex:i];
            }
            
            break;
        
        case 'd':
            {
                double val = va_arg(args, double);
                [self setArgument:&val atIndex:i];
            }
            
            break;
        
        case 'B':
            {
                _Bool val = (_Bool)va_arg(args, int);
                [self setArgument:&val atIndex:i];
            }
            
            break;
        
        case '*':
            {
                char *val = va_arg(args, char *);
                [self setArgument:&val atIndex:i];
            }
            
            break;
        
        case '@':
            {
                __unsafe_unretained id val = va_arg(args, id);
                [self setArgument:&val atIndex:i];

                if (type[1] == '?') {
                    // @? is undocumented, but apparently used to represent
                    // a block -- not sure how to disambiguate it from
                    // a separate @ and ?, but I assume that a block parameter
                    // is a more common case than that
                    ++type;
                }
            }
            
            break;
        
        case '#':
            {
                Class val = va_arg(args, Class);
                [self setArgument:&val atIndex:i];
            }
            
            break;
        
        case ':':
            {
                SEL val = va_arg(args, SEL);
                [self setArgument:&val atIndex:i];
            }
            
            break;
        
        case '[':
            NSLog(@"Unexpected array within method argument type code \"%s\", cannot set invocation argument!", type);
            return NO;
        
        case 'b':
            NSLog(@"Unexpected bitfield within method argument type code \"%s\", cannot set invocation argument!", type);
            return NO;
        
        case '{':
            NSLog(@"Cannot get variable argument for a method that takes a struct argument!");
            return NO;
            
        case '(':
            NSLog(@"Cannot get variable argument for a method that takes a union argument!");
            return NO;
        
        case '^':
            switch (type[1]) {
            case 'c':
            case 'C':
                {
                    char *val = va_arg(args, char *);
                    [self setArgument:&val atIndex:i];
                }
                
                break;
            
            case 'i':
            case 'I':
                {
                    int *val = va_arg(args, int *);
                    [self setArgument:&val atIndex:i];
                }
                
                break;
            
            case 's':
            case 'S':
                {
                    short *val = va_arg(args, short *);
                    [self setArgument:&val atIndex:i];
                }
                
                break;
            
            case 'l':
            case 'L':
                {
                    long *val = va_arg(args, long *);
                    [self setArgument:&val atIndex:i];
                }
                
                break;
            
            case 'q':
            case 'Q':
                {
                    long long *val = va_arg(args, long long *);
                    [self setArgument:&val atIndex:i];
                }
                
                break;
            
            case 'f':
                {
                    float *val = va_arg(args, float *);
                    [self setArgument:&val atIndex:i];
                }
                
                break;
            
            case 'd':
                {
                    double *val = va_arg(args, double *);
                    [self setArgument:&val atIndex:i];
                }
                
                break;
            
            case 'B':
                {
                    _Bool *val = va_arg(args, _Bool *);
                    [self setArgument:&val atIndex:i];
                }
                
                break;
            
            case 'v':
                {
                    void *val = va_arg(args, void *);
                    [self setArgument:&val atIndex:i];
                }
                
                break;
            
            case '*':
            case '@':
            case '#':
            case '^':
            case '[':
                {
                    void **val = va_arg(args, void **);
                    [self setArgument:&val atIndex:i];
                }
                
                break;
            
            case ':':
                {
                    SEL *val = va_arg(args, SEL *);
                    [self setArgument:&val atIndex:i];
                }
                
                break;
            
            case '{':
                {
                    empty_struct_ptr_t val = va_arg(args, empty_struct_ptr_t);
                    [self setArgument:&val atIndex:i];
                }
                
                break;
            
            case '(':
                {
                    empty_union_ptr_t val = va_arg(args, empty_union_ptr_t);
                    [self setArgument:&val atIndex:i];
                }
                
                break;

            case '?':
                {
                    // assume that this is a pointer to a function pointer
                    //
                    // even if it's not, the fact that it's
                    // a pointer-to-something gives us a good chance of not
                    // causing alignment or size problems
                    IMP *ptr = va_arg(args, IMP *);
                    [self setArgument:&ptr atIndex:i];
                }

                break;
            
            case 'b':
            default:
                NSLog(@"Pointer to unexpected type within method argument type code \"%s\", cannot set method invocation!", type);
                return NO;
            }
            
            break;
        
        case '?':
            {
                // this is PROBABLY a function pointer, but the documentation
                // leaves room open for uncertainty, so at least log a message
                NSLog(@"Assuming method argument type code \"%s\" is a function pointer", type);

                IMP ptr = va_arg(args, IMP);
                [self setArgument:&ptr atIndex:i];
            }

            break;
            
        default:
            NSLog(@"Unexpected method argument type code \"%s\", cannot set method invocation!", type);
            return NO;
        }
    }

    return YES;
}
@end
