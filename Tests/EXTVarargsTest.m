//
//  EXTVarargsTest.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 20.06.12.
//  Copyright (C) 2012 Justin Spahr-Summers.
//  Released under the MIT license.
//

#import "EXTVarargsTest.h"

static NSString *varargs_test_func (NSString *base, const char *types, ...) {
    NSArray *args = unpack_args(types);
    return [base stringByAppendingFormat:@"+%@", [args componentsJoinedByString:@","]];
}

#define varargs_test_func(...) \
        varargs_test_func(pack_args(1, __VA_ARGS__))

static NSString *varargs_test_func_no_constants (const char *types, ...) {
    NSArray *args = unpack_args(types);
    return [args componentsJoinedByString:@","];
}

#define varargs_test_func_no_constants(...) \
        varargs_test_func_no_constants(pack_args(0, __VA_ARGS__))

static id block_test (const char *types, ...) {
    return [unpack_args(types) lastObject];
}

#define block_test(...) \
        block_test(pack_varargs(__VA_ARGS__))

@implementation EXTVarargsTest

- (NSUInteger)varargs_test_method:(const char *)types, ... {
    NSArray *args = unpack_args(types);
    return args.count;
}

- (void)testBase {
    NSString *str = varargs_test_func(@"foo");
    STAssertEqualObjects(str, @"foo+", @"");
}

- (void)testOneArgument {
    NSString *str = varargs_test_func(@"foo", 5.5);
    STAssertEqualObjects(str, @"foo+5.5", @"");
}

- (void)testMultipleArguments {
    NSString *str = varargs_test_func(@"foo", 5.5, @"bar", "fuzz");
    STAssertEqualObjects(str, @"foo+5.5,bar,fuzz", @"");
}

- (void)testMaximumArguments {
    NSString *str = varargs_test_func(@"foo", 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19);
    STAssertEqualObjects(str, @"foo+1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19", @"");
}

- (void)testFunctionWithoutConstantArguments {
    NSString *str = varargs_test_func_no_constants((char)'b', 3.14, (BOOL)YES, (_Bool)false, "foo", @"bar");
    STAssertEqualObjects(str, @"b,3.14,1,0,foo,bar", @"");
}

- (void)testBlockArgument {
    id block = block_test(^{ return 5; });
    STAssertFalse([block isKindOfClass:[NSValue class]], @"");

    int (^typedBlock)(void) = block;
    STAssertEquals(typedBlock(), 5, @"");
}

- (void)testEmptyMethodInvocation {
    NSUInteger count = [self varargs_test_method:empty_varargs];
    STAssertEquals(count, (NSUInteger)0, @"");
}

- (void)testMethodInvocation {
    NSUInteger count = [self varargs_test_method:pack_varargs("foo", @"bar", 3.14f, 'b')];
    STAssertEquals(count, (NSUInteger)4, @"");
}

@end
