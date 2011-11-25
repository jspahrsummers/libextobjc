//
//  EXTAspectTest.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 25.11.11.
//  Released into the public domain.
//

#import "EXTAspectTest.h"

@interface AspectTestClass : NSObject <TestAspect, OtherTestAspect>
- (void)testMethod:(int)value;
@end

@implementation AspectTestClass
- (void)testMethod:(int)value; {
    NSParameterAssert(value == 42);
}

- (BOOL)testOtherMethod {
    return YES;
}

+ (double)testClassMethodWithString:(NSString *)str length:(NSUInteger)length {
    NSParameterAssert([str isEqualToString:@"foobar"]);
    NSParameterAssert([str length] == length);
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
@end

@aspectimplementation(OtherTestAspect)
- (void)advise:(void (^)(void))body {
    NSLog(@"about to call %s on %@", sel_getName(_cmd), self);
    body();
    NSLog(@"called %s on %@", sel_getName(_cmd), self);
}
@end

@implementation EXTAspectTest

- (void)testAspects {
    AspectTestClass *obj = [[AspectTestClass alloc] init];
    STAssertNotNil(obj, @"");

    [obj testMethod:42];

    STAssertTrue([obj testOtherMethod], @"");
    STAssertEqualsWithAccuracy([AspectTestClass testClassMethodWithString:@"foobar" length:6], 3.14, 0.01, @"");
}

@end
