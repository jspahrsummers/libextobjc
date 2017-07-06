//
//  EXTPrivateMethodTest.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 2012-06-26.
//  Copyright (C) 2012 Justin Spahr-Summers.
//  Released under the MIT license.
//

#import "EXTPrivateMethodTest.h"

// make sure failed private methods don't crash the test (since we explicitly
// test such a case below)
#ifndef NDEBUG
#define NDEBUG
#endif

#undef DEBUG
#import "EXTPrivateMethod.h"

@interface PrivateClass : NSObject
@end

@private(PrivateClass)
- (BOOL)privateMethod;
+ (BOOL)privateMethod;

@property (nonatomic, assign, getter = isPrivate) BOOL private;

// this should warn about a conflict with NSObject
- (NSString *)description;
@end

@interface PrivateSubclass : PrivateClass
// these should warn about conflicts with PrivateClass
- (BOOL)privateMethod;
- (BOOL)isPrivate;
- (void)setPrivate:(BOOL)value;
@end

@implementation EXTPrivateMethodTest

- (void)testClassRespondsToPrivateMethods {
	
    XCTAssertTrue([PrivateClass privateMethod], @"");
    PrivateClass *obj = [PrivateClass new];
	
    XCTAssertFalse(obj.private, @"");
    XCTAssertFalse([obj privateMethod], @"");

    obj.private = YES;
    XCTAssertTrue(obj.private, @"");
    XCTAssertTrue([obj privateMethod], @"");
}

- (void)testConflictingMethodsStillUseOverrides {
    PrivateSubclass *obj = [PrivateSubclass new];
	
    XCTAssertEqualObjects(obj.description, @"foobar", @"");
    XCTAssertTrue([obj privateMethod], @"");
    XCTAssertFalse(obj.private, @"");
}

@end

@implementation PrivateClass
@synthesize private = _private;

- (BOOL)privateMethod {
    return self.private;
}

+ (BOOL)privateMethod {
    return YES;
}

- (NSString *)description {
    return @"foobar";
}

@end

@implementation PrivateSubclass

- (BOOL)privateMethod {
    return YES;
}

- (BOOL)isPrivate {
    return NO;
}

- (void)setPrivate:(BOOL)value {
}

@end
