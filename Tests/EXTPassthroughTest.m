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
@property (nonatomic, getter = isEnabled) BOOL enabled;

- (void)voidMethod;
- (int)methodWithString:(NSString *)str;
- (int)methodWithString:(NSString *)str number:(NSNumber *)num;
@end

@interface OuterClass : NSObject
@property (nonatomic, strong) InnerClass *inner;
@end

@interface OuterClass (DelegatedMethods)
@property (nonatomic, getter = isEnabled) BOOL enabled;

- (void)renamedMethod;
- (int)methodWithString:(NSString *)str;
- (int)methodWithString:(NSString *)str number:(NSNumber *)num;
@end

@implementation EXTPassthroughTest

- (void)testPassthroughMethods {
    OuterClass *outer = [[OuterClass alloc] init];
    STAssertNotNil(outer, @"");

    [outer renamedMethod];
    STAssertEquals([outer methodWithString:@"foo"], 3, @"");
    STAssertEquals([outer methodWithString:@"foobar" number:@5], 11, @"");
}

- (void)testPassthroughProperty {
    OuterClass *outer = [[OuterClass alloc] init];
    STAssertNotNil(outer, @"");
    STAssertFalse(outer.enabled, @"");
    STAssertFalse(outer.inner.enabled, @"");

    outer.enabled = YES;
    STAssertTrue(outer.enabled, @"");
    STAssertTrue(outer.inner.enabled, @"");
}

@end

@implementation OuterClass
@passthrough(OuterClass, renamedMethod, self.inner, voidMethod);
@passthrough(OuterClass, methodWithString:, self.inner);
@passthrough(OuterClass, methodWithString:number:, [self inner]);
@passthrough(OuterClass, isEnabled, self.inner);
@passthrough(OuterClass, setEnabled:, self.inner);

- (id)init {
    self = [super init];
    if (!self)
        return nil;

    self.inner = [[InnerClass alloc] init];
    return self;
}

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
