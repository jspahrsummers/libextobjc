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

@multimethod(+match:, NSNumber *obj) {
    return [obj description];
}

@end

@implementation EXTMultimethodTest

- (void)testInstanceMethod {
    MultimethodObject *obj = [[MultimethodObject alloc] init];

    STAssertEqualObjects([obj match:@5 with:nil], @"left number", @"");
    STAssertEqualObjects([obj match:nil with:@10], @"right number", @"");
    STAssertEqualObjects([obj match:@"foo" with:@"bar"], @"foobar", @"");
    STAssertEqualObjects([obj match:nil with:nil], @"unknown", @"");
}

- (void)testClassMethod {
    STAssertEqualObjects([MultimethodObject match:nil], @"unknown", @"");
    STAssertEqualObjects([MultimethodObject match:[NSObject new]], @"unknown", @"");
    STAssertEqualObjects([MultimethodObject match:@3.14], @"3.14", @"");
}

@end
