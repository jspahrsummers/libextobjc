//
//  EXTTupleTest.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 18.06.12.
//  Copyright (C) 2012 Justin Spahr-Summers.
//  Released under the MIT license.
//

#import "EXTTupleTest.h"

@implementation EXTTupleTest

- (EXTTuple2)tupleMethod {
    return tuple(@"foobar", @5);
}

- (void)testTuples {
    EXTTuple2 t = [self tupleMethod];
	
    XCTAssertEqualObjects(t.v0, @"foobar", @"");
    XCTAssertEqualObjects(t.v1, @5, @"");
}

- (void)testMultipleAssignment {
    NSString *str;
    NSNumber *num;

    multivar(str, num) = unpack([self tupleMethod]);

    XCTAssertEqualObjects(str, @"foobar", @"");
    XCTAssertEqualObjects(num, @5, @"");
}

- (void)testMultipleAssignmentRvalue {
    NSString *str;
    NSNumber *num;

    NSString *sameStr = multivar(str, num) = unpack([self tupleMethod]);

    XCTAssertEqualObjects(str, @"foobar", @"");
    XCTAssertEqualObjects(sameStr, str, @"");
    XCTAssertEqualObjects(num, @5, @"");
}

- (void)testUnpackingInlineTuple {
    NSString *str;
    NSNumber *num;

    multivar(str, num) = unpack(tuple(@"foo", @3));

    XCTAssertEqualObjects(str, @"foo", @"");
    XCTAssertEqualObjects(num, @3, @"");
}

@end
