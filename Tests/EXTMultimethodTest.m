//
//  EXTMultimethodTest.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 23.06.12.
//  Copyright (C) 2012 Justin Spahr-Summers.
//  Released under the MIT license.
//

#import "EXTMultimethodTest.h"

@interface MultimethodClass : NSObject
@end

@interface MultimethodClass (Multimethods)
- (NSString *)match:(id)obj with:(id)obj2;
+ (NSString *)match:(id)obj;
@end

@interface MultimethodSubclass : MultimethodClass
@end

@implementation MultimethodClass
@load_multimethods(MultimethodClass);

@multimethod(-match:, id obj, with:, id obj2) {
    return @"unknown";
}

@multimethod(-match:, NSNumber *obj, with:, id obj2) {
    return @"left number";
}

@multimethod(-match:, id obj, with:, NSNumber *obj2) {
    return @"right number";
}

@multimethod(-match:, NSString *obj, with:, NSString *obj2) {
    return [obj stringByAppendingString:obj2];
}

@multimethod(+match:, id obj) {
    return @"unknown";
}

@multimethod(+match:, Class cls) {
    return [cls description];
}

@multimethod(+match:, NSValue *obj) {
    return @"value";
}

@multimethod(+match:, NSNumber *obj) {
    return [obj description];
}

@end

@implementation MultimethodSubclass
@load_multimethods(MultimethodSubclass);

@multimethod(-match:, NSNumber *obj, with:, NSNumber *obj2) {
    return @"both numbers";
}

@multimethod(+match:, NSString *str) {
    return str;
}

@end

@implementation EXTMultimethodTest

- (void)testInstanceMethod {
    MultimethodClass *obj = [[MultimethodClass alloc] init];
	
    XCTAssertEqualObjects([obj match:@5 with:nil], @"left number", @"");
    XCTAssertEqualObjects([obj match:@5 with:@"buzz"], @"left number", @"");
    XCTAssertEqualObjects([obj match:@5 with:[NSObject class]], @"left number", @"");

    XCTAssertEqualObjects([obj match:nil with:@10], @"right number", @"");
    XCTAssertEqualObjects([obj match:@"foo" with:@10], @"right number", @"");
    XCTAssertEqualObjects([obj match:[NSObject class] with:@10], @"right number", @"");

    XCTAssertEqualObjects([obj match:@"foo" with:@"bar"], @"foobar", @"");
    XCTAssertNil([obj match:nil with:@"bar"], @"");

    XCTAssertEqualObjects([obj match:nil with:nil], @"unknown", @"");
    XCTAssertEqualObjects([obj match:[NSObject new] with:nil], @"unknown", @"");
    XCTAssertEqualObjects([obj match:nil with:[NSObject new]], @"unknown", @"");
    XCTAssertEqualObjects([obj match:@"fuzz" with:[NSObject new]], @"unknown", @"");
    XCTAssertEqualObjects([obj match:[NSObject class] with:[NSObject new]], @"unknown", @"");
}

- (void)testClassMethod {
    XCTAssertEqualObjects([MultimethodClass match:nil], @"unknown", @"");
    XCTAssertEqualObjects([MultimethodClass match:[NSObject new]], @"unknown", @"");
    XCTAssertEqualObjects([MultimethodClass match:[NSValue valueWithPointer:NULL]], @"value", @"");
    XCTAssertEqualObjects([MultimethodClass match:@3.14], @"3.14", @"");
    XCTAssertEqualObjects([MultimethodClass match:[NSString class]], @"NSString", @"");

    double value = 3.14;
    XCTAssertEqualObjects([MultimethodClass match:[NSValue valueWithBytes:&value objCType:@encode(double)]], @"value", @"");
}

- (void)testMultimethodInheritance {
    XCTAssertEqualObjects([MultimethodSubclass match:nil], @"unknown", @"");
    XCTAssertEqualObjects([MultimethodSubclass match:[NSObject class]], @"NSObject", @"");
    XCTAssertEqualObjects([MultimethodSubclass match:@"foobar"], @"foobar", @"");

    MultimethodSubclass *obj = [[MultimethodSubclass alloc] init];

    XCTAssertEqualObjects([obj match:@5 with:nil], @"left number", @"");
    XCTAssertEqualObjects([obj match:nil with:@10], @"right number", @"");
    XCTAssertEqualObjects([obj match:@5 with:@10], @"both numbers", @"");
}

@end
