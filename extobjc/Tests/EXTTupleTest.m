//
//  EXTTupleTest.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 18.06.12.
//  Released into the public domain.
//

#import "EXTTupleTest.h"

@implementation EXTTupleTest

- (EXTTuple2)tupleMethod {
    return tuple(@"foobar", @5);
}

- (void)testTuples {
    EXTTuple2 t = [self tupleMethod];

    STAssertEqualObjects(t.v0, @"foobar", @"");
    STAssertEqualObjects(t.v1, @5, @"");
}

- (void)testMultipleAssignment {
    NSString *str;
    NSNumber *num;

    multivar(str, num) = unpack([self tupleMethod]);

    STAssertEqualObjects(str, @"foobar", @"");
    STAssertEqualObjects(num, @5, @"");
}

- (void)testUnpackingInlineTuple {
    NSString *str;
    NSNumber *num;

    multivar(str, num) = unpack(tuple(@"foo", @3));

    STAssertEqualObjects(str, @"foo", @"");
    STAssertEqualObjects(num, @3, @"");
}

@end
