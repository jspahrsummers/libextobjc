//
//  EXTNilTest.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-04-25.
//  Copyright (C) 2012 Justin Spahr-Summers.
//  Released under the MIT license.
//

#import "EXTNilTest.h"
#import "EXTRuntimeTestProtocol.h"

@implementation EXTNilTest

- (void)testReturnValues {
    id obj = [EXTNil null];

    // irony
    XCTAssertNotNil(obj, @"");
    
    XCTAssertEqualObjects(obj, obj, @"EXTNil should equal itself");
    XCTAssertEqual([obj init], obj, @"-init on EXTNil should return the same object without any change");
    XCTAssertNil([obj alloc], @"+alloc on EXTNil instance should return nil");

    XCTAssertEqual([obj uppercaseString], (NSString *)nil, @"any method on EXTNil object should return zero value");
    XCTAssertEqual((NSInteger)[obj length], (NSInteger)0, @"any method on EXTNil object should return zero value");
    XCTAssertEqualWithAccuracy([obj doubleValue], 0.0, 0.01, @"any method on EXTNil object should return zero value");
    XCTAssertTrue(NSEqualRanges([obj rangeOfString:@""], NSMakeRange(0, 0)), @"any method on EXTNil object should return zero value");

    NSArray *arr = @[obj];
    XCTAssertNotNil(arr, @"");
    XCTAssertEqualObjects(arr[0], obj, @"EXTNil object properties should be preserved in a collection");
    XCTAssertEqualObjects([arr[0] target], nil, @"EXTNil object properties should be preserved in a collection");
}

- (void)testKeyValueCoding {
    id obj = [EXTNil null];
    [obj setValue:@"foo" forKey:@"bar"];

    NSDictionary *values = [obj dictionaryWithValuesForKeys:@[@"bar"]];
    XCTAssertNil(values, @"");
}

- (void)testProtocol {
    id test = nil;
    XCTAssertNoThrow([test optionalInstanceMethod], @"nil handles optional instance methods");
    XCTAssertNoThrow([test optionalClassMethod], @"nil handles optional class methods");
    test = [EXTNil null];
    XCTAssertNoThrow([test optionalInstanceMethod], @"EXTNil handles optional instance methods");
    XCTAssertNoThrow([test optionalClassMethod], @"EXTNil handles optional class methods");
}

@end
