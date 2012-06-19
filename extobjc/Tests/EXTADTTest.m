//
//  EXTADTTest.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 19.06.12.
//
//

#import "EXTADTTest.h"

ADT(MyType,
    constructor(Red),
    constructor(Green),
    constructor(Blue),
    constructor(Other, int)
);

@implementation EXTADTTest

- (void)testConstruction {
    MyType t = Red();
    STAssertTrue(t.tag == Red, @"");

    MyType t2 = Other(123);
    STAssertTrue(t2.tag == Other, @"");
    STAssertEquals(t2.Other.v0, 123, @"");
}

@end
