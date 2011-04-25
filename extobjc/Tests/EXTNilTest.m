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
	STAssertEqualObjects(obj, obj, @"EXTNil should equal itself");
	STAssertEqualObjects(obj, [[obj copy] autorelease], @"EXTNil copy should equal EXTNil");

	NSArray *arr = [NSArray arrayWithObject:obj];
	STAssertNotNil(arr, @"");
	STAssertEqualObjects([arr objectAtIndex:0], obj, @"EXTNil object properties should be preserved in a collection");
	STAssertEqualObjects([[arr objectAtIndex:0] target], nil, @"EXTNil object properties should be preserved in a collection");
}

@end
