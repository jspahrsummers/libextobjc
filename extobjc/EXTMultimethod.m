//
//  EXTMultimethod.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 23.06.12.
//  Copyright (C) 2012 Justin Spahr-Summers.
//  Released under the MIT license.
//

#import "EXTMultimethod.h"
#import "EXTRuntimeExtensions.h"
#import "EXTScope.h"

#define EXT_MULTIMETHOD_DEBUG 0

typedef EXTMultimethodAttributes *(*ext_copyMultimethodAttributes_IMP)(void);

@interface EXTMultimethodAttributes ()
@property (nonatomic, readwrite) SEL selector;
@property (nonatomic, getter = isClassMethod, readwrite) BOOL classMethod;
@property (nonatomic, readwrite) IMP implementation;
@property (nonatomic, readwrite) NSUInteger parameterCount;
@property (nonatomic, readwrite) const Class *parameterClasses;
@end

static NSString *ext_multimethodArgumentListDescription (const id *args, size_t argCount) {
    NSMutableString *str = [@"(" mutableCopy];

    for (size_t i = 0; i < argCount; ++i) {
        if (i > 0)
            [str appendString:@", "];

        id arg = args[i];
        if (!arg)
            [str appendString:@"nil"];
        else
            [str appendFormat:@"%@ %@", object_getClass(arg), arg];
    }

    [str appendString:@")"];
    return str;
}

static NSArray *ext_collectMultimethodImplementations (Class descendantClass, SEL multimethodSelector) {
    if (!descendantClass)
        return nil;

    NSArray *implementations = objc_getAssociatedObject(descendantClass, multimethodSelector);

    NSArray *superclassImplementations = ext_collectMultimethodImplementations(class_getSuperclass(descendantClass), multimethodSelector);
    if (superclassImplementations) {
        // keep the most descendant implementations at the top for our stable
        // sort in ext_bestMultimethod()
        implementations = [implementations arrayByAddingObjectsFromArray:superclassImplementations];
    }

    return implementations;
}

static EXTMultimethodAttributes *ext_bestMultimethod (NSArray *implementations, const id *args, size_t argCount) {
    NSMutableArray *possibilities = [NSMutableArray arrayWithCapacity:implementations.count];

    // only consider implementations that match the arguments given
    [implementations enumerateObjectsUsingBlock:^(EXTMultimethodAttributes *attributes, NSUInteger implementationIndex, BOOL *stop){
        #if EXT_MULTIMETHOD_DEBUG
        NSLog(@"*** Considering implementation %@", attributes);
        #endif

        BOOL possible = YES;

        for (NSUInteger argIndex = 0; argIndex < argCount; ++argIndex) {
            NSCAssert(argIndex < attributes.parameterCount, @"Argument index %lu is out-of-bounds of parameter count %lu", (unsigned long)argIndex, (unsigned long)attributes.parameterCount);

            id arg = args[argIndex];
            Class paramClass = attributes.parameterClasses[argIndex];

            // if there's no parameter class, the argument is of type 'id' (and
            // thus anything is valid)
            //
            // likewise, if the argument is nil, it might match anything
            if (paramClass && arg) {
                if ([paramClass isEqual:[EXTMultimethod_Class_Parameter_Placeholder class]]) {
                    // the argument has to be a class object
                    Class argClass = object_getClass(arg);

                    if (!class_isMetaClass(argClass)) {
                        #if EXT_MULTIMETHOD_DEBUG
                        NSLog(@"*** Rejecting implementation %@ because argument %lu is not a class object", attributes, (unsigned long)argIndex);
                        #endif

                        possible = NO;
                        break;
                    }
                } else if (![arg isKindOfClass:paramClass]) {
                    #if EXT_MULTIMETHOD_DEBUG
                    NSLog(@"*** Rejecting implementation %@ because argument %lu is not of class %@", attributes, (unsigned long)argIndex, paramClass);
                    #endif

                    possible = NO;
                    break;
                }
            }
        }

        if (possible)
            [possibilities addObject:attributes];
    }];

    if (!possibilities.count)
        return nil;

    // sort by best match, and keep equal implementations in the same relative
    // position (descendants before ancestors) so that descendant multimethods
    // properly override ancestors
    //
    // NSOrderedAscending == the left method is a closer match
    // NSOrderedDescending == the right method is a closer match
    [possibilities sortWithOptions:NSSortStable usingComparator:^ NSComparisonResult (EXTMultimethodAttributes *left, EXTMultimethodAttributes *right){
        NSCAssert(left.parameterCount == right.parameterCount, @"Two implementations of the same multimethod should have the same number of parameters");

        /*
         * Nil arguments should bind more tightly to 'id' than to any specific
         * type, but other non-nil arguments should carry more weight, since
         * they provide more information. Therefore, we try to match specific
         * types first, and only fall back to nil-id binding if it would
         * otherwise be ambiguous.
         *
         * If this is less than zero, the left multimethod is a better fit;
         * greater than zero means the right multimethod is better.
         */
        NSInteger nilArgumentWeight = 0;

        for (NSUInteger i = 0; i < left.parameterCount; ++i) {
            Class leftClass = left.parameterClasses[i];
            Class rightClass = right.parameterClasses[i];
            id arg = args[i];

            if (!leftClass) {
                if (!rightClass) {
                    continue;
                } else {
                    if (!arg) {
                        --nilArgumentWeight;
                        continue;
                    } else {
                        return NSOrderedDescending;
                    }
                }
            } else if (!rightClass) {
                if (!arg) {
                    ++nilArgumentWeight;
                    continue;
                } else {
                    return NSOrderedAscending;
                }
            }

            if ([leftClass isEqual:rightClass])
                continue;

            if ([leftClass isSubclassOfClass:rightClass]) {
                return NSOrderedAscending;
            } else if ([rightClass isSubclassOfClass:leftClass]) {
                return NSOrderedDescending;
            }
        }

        // well, we've exhausted any differences in specific types, so now fall
        // back to matching nil arguments with the most general parameters (like
        // "id")
        if (nilArgumentWeight < 0)
            return NSOrderedAscending;
        else if (nilArgumentWeight > 0)
            return NSOrderedDescending;
        else
            return NSOrderedSame;
    }];

    #if EXT_MULTIMETHOD_DEBUG
    NSLog(@"*** Matching multimethod implementations, in order of best match: %@", possibilities);
    #endif

    // and return the bestest match
    return possibilities[0];
}

Class ext_multimethod_parameterClassFromEncoding (const char *encoding) {
    if (*encoding == *(@encode(id)))
        return Nil;
    else if (*encoding == *(@encode(Class)))
        return [EXTMultimethod_Class_Parameter_Placeholder class];

    const char *openingBrace = strchr(encoding, '{');
    if (!openingBrace)
        return Nil;

    ++openingBrace;

    const char *eqSign = strchr(openingBrace, '=');
    if (!eqSign)
        return Nil;

    NSUInteger nameLen = eqSign - openingBrace;
    if (!nameLen)
        return Nil;

    char name[nameLen + 1];
    strncpy(name, openingBrace, nameLen);
    name[nameLen] = '\0';

    return objc_getClass(name);
}

BOOL ext_loadMultimethods (Class targetClass) {
    unsigned methodCount = 0;
    Method *methods = class_copyMethodList(object_getClass(targetClass), &methodCount);
    if (!methods)
        return NO;

    NSMutableDictionary *implementationsBySelectorName = [NSMutableDictionary dictionary];

    for (unsigned i = 0; i < methodCount; ++i) {
        SEL selector = method_getName(methods[i]);
        NSString *name = NSStringFromSelector(selector);
        
        if (![name hasPrefix:@"ext_copyMultimethodAttributes_"])
            continue;

        ext_copyMultimethodAttributes_IMP impl = (ext_copyMultimethodAttributes_IMP)method_getImplementation(methods[i]);
        EXTMultimethodAttributes *attributes = impl();
        if (!attributes)
            return NO;

        NSString *metamethodName = NSStringFromSelector(attributes.selector);
        if (attributes.classMethod)
            metamethodName = [@"+" stringByAppendingString:metamethodName];
        else
            metamethodName = [@"-" stringByAppendingString:metamethodName];

        NSMutableArray *implementations = implementationsBySelectorName[metamethodName];

        if (!implementations) {
            implementations = [NSMutableArray array];
            implementationsBySelectorName[metamethodName] = implementations;
        }

        [implementations addObject:attributes];
    }

    for (NSString *name in implementationsBySelectorName) {
        NSArray *implementations = implementationsBySelectorName[name];
        EXTMultimethodAttributes *attributes = implementations.lastObject;

        // associate the multimethod implementations with the class, so we can
        // traverse the implementations associated with each class in
        // a hierarchy when dispatching
        Class injectionClass = (attributes.classMethod ? object_getClass(targetClass) : targetClass);
        objc_setAssociatedObject(injectionClass, attributes.selector, implementations, OBJC_ASSOCIATION_COPY_NONATOMIC);

        id dispatchMethodBlock = nil;

        #define ext_multimethod_dispatch_case(N) \
            case N: { \
                dispatchMethodBlock = [^ id (id self, metamacro_for_cxt(N, ext_multimethod_dispatch_param_iter_,,)) { \
                    id args[] = { metamacro_for_cxt(N, ext_multimethod_dispatch_args_iter_,,) }; \
                    \
                    if (EXT_MULTIMETHOD_DEBUG) { \
                        NSLog(@"*** Looking for best implementation of multimethod %@ to match argument list %@", \
                            name, ext_multimethodArgumentListDescription(args, N)); \
                    } \
                    \
                    /* only consider multimethod implementations from this class
                     * and upward, so subclass' invocations of "super" behave as
                     * expected */ \
                    NSArray *implementations = ext_collectMultimethodImplementations(injectionClass, attributes.selector); \
                    EXTMultimethodAttributes *match = ext_bestMultimethod(implementations, args, N); \
                    \
                    if (match) { \
                        if (EXT_MULTIMETHOD_DEBUG) { \
                            NSLog(@"*** Invoking multimethod %@ for argument list %@", \
                                match, ext_multimethodArgumentListDescription(args, N)); \
                        } \
                        \
                        return ((id (*)(id, SEL, metamacro_for_cxt(N, ext_multimethod_dispatch_param_iter_,,)))match.implementation) \
                            (self, attributes.selector, metamacro_for_cxt(N, ext_multimethod_dispatch_args_iter_,,)); \
                    } \
                    \
                    Method superclassMethod = NULL; \
                    Class injectionSuperclass = object_getClass(injectionClass); \
                    \
                    if (injectionSuperclass) \
                        superclassMethod = class_getInstanceMethod(injectionSuperclass, attributes.selector); \
                    \
                    if (superclassMethod) { \
                        IMP superclassIMP = method_getImplementation(superclassMethod); \
                        return ((id (*)(id, SEL, metamacro_for_cxt(N, ext_multimethod_dispatch_param_iter_,,)))superclassIMP) \
                            (self, attributes.selector, metamacro_for_cxt(N, ext_multimethod_dispatch_args_iter_,,)); \
                    } \
                    \
                    [NSException \
                        raise:NSInvalidArgumentException \
                        format:@"No multimethod implementation found to handle argument list %@", \
                            ext_multimethodArgumentListDescription(args, N) \
                    ]; \
                    \
                    abort(); \
                } copy]; \
                \
                break; \
            }

        #define ext_multimethod_dispatch_param_iter_(INDEX, CONTEXT) \
            /* insert a comma for each argument after the first */ \
            metamacro_if_eq(0, INDEX)()(,) \
            id metamacro_concat(param, INDEX)

        #define ext_multimethod_dispatch_args_iter_(INDEX, CONTEXT) \
            /* insert a comma for each argument after the first */ \
            metamacro_if_eq(0, INDEX)()(,) \
            metamacro_concat(param, INDEX)

        switch (attributes.parameterCount) {
            ext_multimethod_dispatch_case(1)
            ext_multimethod_dispatch_case(2)
            ext_multimethod_dispatch_case(3)
            ext_multimethod_dispatch_case(4)
            ext_multimethod_dispatch_case(5)
            ext_multimethod_dispatch_case(6)
            ext_multimethod_dispatch_case(7)
            ext_multimethod_dispatch_case(8)
            ext_multimethod_dispatch_case(9)
            ext_multimethod_dispatch_case(10)

            default:
                NSLog(@"*** Unsupported number of parameters for multimethod: %lu", (unsigned long)attributes.parameterCount);
                abort();
        }

        NSMutableString *typeString = [NSMutableString stringWithFormat:@"%s%s%s", @encode(id), @encode(id), @encode(SEL)];
        for (NSUInteger i = 0; i < attributes.parameterCount; ++i)
            [typeString appendFormat:@"%s", @encode(id)];

        BOOL success = class_addMethod(
            injectionClass,
            attributes.selector,
            imp_implementationWithBlock(dispatchMethodBlock),
            typeString.UTF8String
        );
        
        if (!success)
            return NO;
    }

    return YES;
}

@implementation EXTMultimethodAttributes

- (id)initWithName:(const char *)name implementation:(IMP)implementation parameterCount:(NSUInteger)parameterCount parameterClasses:(const Class *)parameterClasses; {
    self = [super init];
    if (!self)
        return nil;

    if (name[0] == '+') {
        self.classMethod = YES;
        ++name;
    } else if (name[0] == '-') {
        ++name;
    }

    NSMutableString *nameString = [NSMutableString stringWithUTF8String:name];

    // sanitize the selector by removing whitespace
    for (;;) {
        NSRange range = [nameString rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (range.location == NSNotFound)
            break;

        [nameString deleteCharactersInRange:range];
    }

    self.selector = NSSelectorFromString(nameString);
    self.implementation = implementation;

    Class *classesCopy = (Class *)malloc(parameterCount * sizeof(*classesCopy));
    if (!classesCopy)
        return nil;

    memcpy(classesCopy, parameterClasses, parameterCount * sizeof(*classesCopy));

    self.parameterCount = parameterCount;
    self.parameterClasses = classesCopy;
    return self;
}

- (void)dealloc {
    free((void *)self.parameterClasses);
    self.parameterClasses = NULL;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (NSUInteger)hash {
    return (NSUInteger)(void *)self.selector;
}

- (BOOL)isEqual:(EXTMultimethodAttributes *)attributes {
    if (![attributes isKindOfClass:[EXTMultimethodAttributes class]])
        return NO;

    return self.implementation == attributes.implementation;
}

- (NSString *)description {
    NSMutableString *str = [NSMutableString stringWithFormat:@"%s (", sel_getName(self.selector)];
    
    for (NSUInteger i = 0; i < self.parameterCount; ++i) {
        if (i > 0)
            [str appendString:@", "];

        Class paramClass = self.parameterClasses[i];
        if (!paramClass)
            [str appendString:@"id"];
        else if ([paramClass isEqual:[EXTMultimethod_Class_Parameter_Placeholder class]])
            [str appendString:@"Class"];
        else
            [str appendString:NSStringFromClass(paramClass)];
    }

    [str appendString:@")"];
    return str;
}

@end

@implementation EXTMultimethod_Class_Parameter_Placeholder
@end
