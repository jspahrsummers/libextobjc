//
//  EXTMultimethodTest.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 23.06.12.
//  Released into the public domain.
//

#import "EXTMultimethodTest.h"

@interface MultimethodObject : NSObject
@end

@interface MultimethodObject (Multimethods)
- (NSString *)match:(id)obj with:(id)obj2;
+ (NSString *)match:(id)obj;
@end

@implementation MultimethodObject
@load_multimethods(MultimethodObject);

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

@multimethod(+match:, NSNumber *obj) {
    return [obj description];
}

@end

@implementation EXTMultimethodTest

- (void)testInstanceMethod {
    MultimethodObject *obj = [[MultimethodObject alloc] init];

    STAssertEqualObjects([obj match:@5 with:nil], @"left number", @"");
    STAssertEqualObjects([obj match:@5 with:@"buzz"], @"left number", @"");
    STAssertEqualObjects([obj match:@5 with:[NSObject class]], @"left number", @"");

    STAssertEqualObjects([obj match:nil with:@10], @"right number", @"");
    STAssertEqualObjects([obj match:@"foo" with:@10], @"right number", @"");
    STAssertEqualObjects([obj match:[NSObject class] with:@10], @"right number", @"");

    STAssertEqualObjects([obj match:@"foo" with:@"bar"], @"foobar", @"");
    STAssertNil([obj match:nil with:@"bar"], @"");

    STAssertEqualObjects([obj match:nil with:nil], @"unknown", @"");
    STAssertEqualObjects([obj match:[NSObject new] with:nil], @"unknown", @"");
    STAssertEqualObjects([obj match:nil with:[NSObject new]], @"unknown", @"");
    STAssertEqualObjects([obj match:@"fuzz" with:[NSObject new]], @"unknown", @"");
    STAssertEqualObjects([obj match:[NSObject class] with:[NSObject new]], @"unknown", @"");
}

- (void)testClassMethod {
    STAssertEqualObjects([MultimethodObject match:nil], @"unknown", @"");
    STAssertEqualObjects([MultimethodObject match:[NSObject new]], @"unknown", @"");
    STAssertEqualObjects([MultimethodObject match:@3.14], @"3.14", @"");
    STAssertEqualObjects([MultimethodObject match:[NSString class]], @"NSString", @"");
}

@end
