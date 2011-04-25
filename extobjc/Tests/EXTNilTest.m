//
//  EXTNilTest.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-04-25.
//  Released into the public domain.
//

#import "EXTNilTest.h"

@implementation EXTNilTest

- (void)testReturnValues {
	id obj = [EXTNil null];

	// irony
	STAssertNotNil(obj, @"");

	STAssertEquals([obj uppercaseString], (NSString *)nil, @"any method on EXTNil object should return zero value");
	STAssertEquals((NSInteger)[obj length], (NSInteger)0, @"any method on EXTNil object should return zero value");
	STAssertEqualsWithAccuracy([obj doubleValue], 0.0, 0.01, @"any method on EXTNil object should return zero value");
	STAssertTrue(NSEqualRanges([obj rangeOfString:@""], NSMakeRange(0, 0)), @"any method on EXTNil object should return zero value");
}

@end
