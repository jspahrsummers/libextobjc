//
//  EXTAspectTest.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 25.11.11.
//  Copyright (C) 2012 Justin Spahr-Summers.
//  Released under the MIT license.
//

#import "EXTAspectTest.h"

@interface AspectTestClass : NSObject <TestAspect, OtherTestAspect> {
@public
    int m_getterAdviceCallCount;
    int m_setterAdviceCallCount;
}
@property (copy) NSString *name;

- (void)testMethod:(int)value;
@end

@implementation AspectTestClass
@synthesize name = m_name;

- (void) incGetterAdviceCallCount
{
    m_getterAdviceCallCount++;
}

- (void) incSetterAdviceCallCount
{
    m_setterAdviceCallCount++;
}

- (void)testMethod:(int)value; {
    NSParameterAssert(value == 42);
}

- (BOOL)testOtherMethod {
    return YES;
}

+ (double)testClassMethodWithString:(NSString *)str length:(NSUInteger)length {
    NSParameterAssert([str isEqualToString:@"foobar"]);
    NSParameterAssert([str length] == length);

    NSLog(@"%s", __func__);
    return 3.14;
}
@end

@aspectimplementation(TestAspect)
- (void)adviseTestOtherMethod:(void (^)(void))body {
    NSLog(@"testing other method");
    body();
}

- (void)advise:(void (^)(void))body testMethod:(int)value {
    NSLog(@"testMethod's value: %i", value);
    body();
}

- (void)adviseSetters:(void (^)(void))body property:(NSString *)property {
    NSLog(@"about to change %@", property);
    [(id)self incSetterAdviceCallCount];
    body();
}

- (void)adviseGetters:(void (^)(void))body property:(NSString *)property {
    NSLog(@"about to fetch %@", property);
    [(id)self incGetterAdviceCallCount];
    body();
}
@end

@aspectimplementation(OtherTestAspect)
- (void)advise:(void (^)(void))body {
    NSLog(@"calling %s on %@", sel_getName(_cmd), self);
    body();
}
@end

@implementation EXTAspectTest

- (void)testAspects {
    AspectTestClass *obj = [[AspectTestClass alloc] init];
    STAssertNotNil(obj, @"");

    STAssertNil(obj.name, @"");
    obj.name = @"MyObject";
    STAssertEqualObjects([obj name], @"MyObject", @"");
    [obj testMethod:42];

    STAssertEquals(obj->m_getterAdviceCallCount, 2, @"");
    STAssertEquals(obj->m_setterAdviceCallCount, 1, @"");
    STAssertTrue([obj testOtherMethod], @"");
    STAssertEqualsWithAccuracy([AspectTestClass testClassMethodWithString:@"foobar" length:6], 3.14, 0.01, @"");
}

@end

