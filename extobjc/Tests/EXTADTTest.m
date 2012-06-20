//
//  EXTADTTest.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 19.06.12.
//
//

#import "EXTADTTest.h"

ADT(Color,
    constructor(Red),
    constructor(Green),
    constructor(Blue),
    constructor(Gray, double alpha),
    constructor(Other, double r, double g, double b)
);

@implementation EXTADTTest

- (void)testConstruction {
    Color c1 = Red();
    STAssertTrue(c1.tag == Red, @"");

    Color c2 = Other(1.0, 0.5, 0.25);
    STAssertTrue(c2.tag == Other, @"");
    STAssertEqualsWithAccuracy(c2.r, 1.0, 0.0001, @"");
    STAssertEqualsWithAccuracy(c2.g, 0.5, 0.0001, @"");
    STAssertEqualsWithAccuracy(c2.b, 0.25, 0.0001, @"");

    Color c3 = Gray(0.75);
    STAssertTrue(c3.tag == Gray, @"");
    STAssertEqualsWithAccuracy(c3.alpha, 0.75, 0.0001, @"");
}

@end
