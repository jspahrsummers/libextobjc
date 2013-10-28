//
//  EXTPassthroughTest.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 2012-07-03.
//  Copyright (C) 2012 Justin Spahr-Summers.
//  Released under the MIT license.
//

#import "EXTPassthroughTest.h"

@interface InnerClass : NSObject

- (void)voidMethod;
- (int)methodWithString:(NSString *)str;
- (int)methodWithString:(NSString *)str number:(NSNumber *)num;

@property (nonatomic, getter = hasFlakyCrust, setter = topWithFlakyCrust:) BOOL flakyCrust;
@property (nonatomic, getter = isALaMode) BOOL aLaMode;
@property (strong, nonatomic, setter = assignFilling:, getter = whatIsTheFilling) NSString * filling;
@property (nonatomic) NSTimeInterval bakingTime;

@end

@interface OuterClass : NSObject
@property (nonatomic, strong) InnerClass *inner;

@property (nonatomic, getter = hasFlakyCrust, setter = topWithFlakyCrust:) BOOL flakyCrust;
@property (nonatomic) BOOL aLaMode;
@property (strong, nonatomic) NSString * fruitType;

@end

@interface OuterClass (DelegatedMethods)

- (void)renamedMethod;
- (int)methodWithString:(NSString *)str;
- (int)methodWithString:(NSString *)str number:(NSNumber *)num;
@end

@interface OuterClass (DelegatedProperty)
@property (nonatomic) NSTimeInterval bakingTime;
@end

@implementation EXTPassthroughTest

- (void)testPassthroughMethods {
    OuterClass *outer = [[OuterClass alloc] init];
    STAssertNotNil(outer, @"");
    
    [outer renamedMethod];
    STAssertEquals([outer methodWithString:@"foo"], 3, @"");
    STAssertEquals([outer methodWithString:@"foobar" number:@5], 11, @"");
}

- (void)testPassthroughPropertyCustomAccessors {
    OuterClass *outer = [[OuterClass alloc] init];
    STAssertNotNil(outer, @"");
    STAssertFalse(outer.flakyCrust, @"");
    STAssertFalse(outer.inner.flakyCrust, @"");
    
    outer.flakyCrust = YES;
    STAssertTrue(outer.flakyCrust, @"");
    STAssertTrue(outer.inner.flakyCrust, @"");
}

- (void)testPassthroughPropertySameBaseNameDifferentAccessors {
    OuterClass *outer = [[OuterClass alloc] init];
    STAssertNotNil(outer, @"");
    STAssertFalse(outer.aLaMode, @"");
    STAssertFalse(outer.inner.aLaMode, @"");
    
    outer.aLaMode = YES;
    STAssertTrue(outer.aLaMode, @"");
    STAssertTrue(outer.inner.aLaMode, @"");
}

- (void)testPassthroughPropertyDifferentNames {
    OuterClass *outer = [[OuterClass alloc] init];
    STAssertNotNil(outer, @"");
    STAssertEqualObjects(nil, outer.fruitType, @"");
    STAssertEqualObjects(nil, outer.inner.filling, @"");
    
    outer.fruitType = @"Pear";
    STAssertEqualObjects(@"Pear", outer.fruitType, @"");
    STAssertEqualObjects(@"Pear", outer.inner.filling, @"");
}

- (void)testPassthroughPropertySameNames {
    OuterClass *outer = [[OuterClass alloc] init];
    STAssertNotNil(outer, @"");
    STAssertEquals(0.0, outer.bakingTime, @"");
    STAssertEquals(0.0, outer.inner.bakingTime, @"");
    
    outer.bakingTime = 75.0;
    STAssertEqualsWithAccuracy(75.0, outer.bakingTime, 0.5, @"");
    STAssertEqualsWithAccuracy(75.0, outer.inner.bakingTime, 0.5, @"");
}


@end

@implementation OuterClass
@passthrough(OuterClass, renamedMethod, self.inner, voidMethod);
@passthrough(OuterClass, methodWithString:, self.inner);
@passthrough(OuterClass, methodWithString:number:, [self inner]);

@passthrough_property(OuterClass, flakyCrust, self.inner);
@passthrough_property(OuterClass, fruitType, self.inner, filling);
@passthrough_property(OuterClass, aLaMode, self.inner, aLaMode);

- (id)init {
    self = [super init];
    if (!self)
        return nil;
    
    self.inner = [[InnerClass alloc] init];
    return self;
}

@end

@implementation OuterClass (DelegatedProperty)
@passthrough_property(OuterClass, bakingTime, self.inner);
@end

@implementation InnerClass

- (void)voidMethod {
}

- (int)methodWithString:(NSString *)str {
    return [self methodWithString:str number:nil];
}

- (int)methodWithString:(NSString *)str number:(NSNumber *)num {
    return (int)[str length] + [num intValue];
}

@end
