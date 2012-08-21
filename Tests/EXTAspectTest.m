//
//  EXTAspectTest.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 25.11.11.
//  Copyright (C) 2012 Justin Spahr-Summers.
//  Released under the MIT license.
//

#import "EXTAspectTest.h"

@interface AspectTestClass : NSObject <TestAspect, OtherTestAspect>
@property (copy) NSString *name;

- (void)testMethod:(int)value;
@end

@implementation AspectTestClass
@synthesize name = m_name;

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
    NSLog(@"about to change %@ on %@", property, [(id)self name]);
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

    obj.name = @"MyObject";
    [obj testMethod:42];

    STAssertTrue([obj testOtherMethod], @"");
    STAssertEqualsWithAccuracy([AspectTestClass testClassMethodWithString:@"foobar" length:6], 3.14, 0.01, @"");
}

@end

