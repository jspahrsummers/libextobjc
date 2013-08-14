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
    STAssertNotNil(obj, @"");
    
    STAssertEqualObjects(obj, obj, @"EXTNil should equal itself");
    STAssertEquals([obj init], obj, @"-init on EXTNil should return the same object without any change");
    STAssertNil([obj alloc], @"+alloc on EXTNil instance should return nil");

    STAssertEquals([obj uppercaseString], (NSString *)nil, @"any method on EXTNil object should return zero value");
    STAssertEquals((NSInteger)[obj length], (NSInteger)0, @"any method on EXTNil object should return zero value");
    STAssertEqualsWithAccuracy([obj doubleValue], 0.0, 0.01, @"any method on EXTNil object should return zero value");
    STAssertTrue(NSEqualRanges([obj rangeOfString:@""], NSMakeRange(0, 0)), @"any method on EXTNil object should return zero value");

    NSArray *arr = @[obj];
    STAssertNotNil(arr, @"");
    STAssertEqualObjects(arr[0], obj, @"EXTNil object properties should be preserved in a collection");
    STAssertEqualObjects([arr[0] target], nil, @"EXTNil object properties should be preserved in a collection");
}

- (void)testKeyValueCoding {
    id obj = [EXTNil null];
    [obj setValue:@"foo" forKey:@"bar"];

    NSDictionary *values = [obj dictionaryWithValuesForKeys:@[@"bar"]];
    STAssertNil(values, @"");
}

- (void)testProtocol {
    id test = nil;
    STAssertNoThrow([test optionalInstanceMethod], @"nil handles optional instance methods");
    STAssertNoThrow([test optionalClassMethod], @"nil handles optional class methods");
    test = [EXTNil null];
    STAssertNoThrow([test optionalInstanceMethod], @"EXTNil handles optional instance methods");
    STAssertNoThrow([test optionalClassMethod], @"EXTNil handles optional class methods");
}

@end
