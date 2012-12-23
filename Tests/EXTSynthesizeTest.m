//
//  EXTSynthesizeTest.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 2012-09-04.
//  Copyright (C) 2012 Justin Spahr-Summers.
//  Released under the MIT license.
//

#import "EXTSynthesizeTest.h"
#import "EXTSynthesize.h"

@interface NSObject (EXTSynthesizeTest)
@property (nonatomic, unsafe_unretained) id testNonatomicAssignProperty;
@property (unsafe_unretained) id testAtomicAssignProperty;

@property (nonatomic, strong) id testNonatomicRetainProperty;
@property (strong) id testAtomicRetainProperty;

@property (nonatomic, copy) id testNonatomicCopyProperty;
@property (copy) id testAtomicCopyProperty;
@end

@implementation NSObject (EXTSynthesizeTest)
@synthesizeAssociation(NSObject, testNonatomicAssignProperty);
@synthesizeAssociation(NSObject, testAtomicAssignProperty);
@synthesizeAssociation(NSObject, testNonatomicRetainProperty);
@synthesizeAssociation(NSObject, testAtomicRetainProperty);
@synthesizeAssociation(NSObject, testNonatomicCopyProperty);
@synthesizeAssociation(NSObject, testAtomicCopyProperty);
@end

@implementation EXTSynthesizeTest

- (void)testAssignProperties {
	NSObject *owner = [[NSObject alloc] init];

	__weak id weakValue = nil;

	@autoreleasepool {
		id value __attribute__((objc_precise_lifetime)) = [@"foobar" mutableCopy];

		weakValue = value;
		STAssertNotNil(weakValue, @"");

		owner.testNonatomicAssignProperty = value;
		STAssertEquals(owner.testNonatomicAssignProperty, value, @"");

		owner.testAtomicAssignProperty = value;
		STAssertEquals(owner.testAtomicAssignProperty, value, @"");
	}

	STAssertNil(weakValue, @"");
}

- (void)testStrongProperties {
	NSObject *owner = [[NSObject alloc] init];

	__weak id weakValue = nil;

	@autoreleasepool {
		id value __attribute__((objc_precise_lifetime)) = [@"foobar" mutableCopy];

		weakValue = value;
		STAssertNotNil(weakValue, @"");

		owner.testNonatomicRetainProperty = value;
		STAssertEquals(owner.testNonatomicRetainProperty, value, @"");

		owner.testAtomicRetainProperty = value;
		STAssertEquals(owner.testAtomicRetainProperty, value, @"");
	}

	STAssertNotNil(weakValue, @"");
	STAssertEquals(owner.testNonatomicRetainProperty, weakValue, @"");
	STAssertEquals(owner.testAtomicRetainProperty, weakValue, @"");
}

- (void)testCopyProperties {
	NSObject *owner = [[NSObject alloc] init];

	__weak id weakValue = nil;

	@autoreleasepool {
		id value __attribute__((objc_precise_lifetime)) = [@"foobar" mutableCopy];

		weakValue = value;
		STAssertNotNil(weakValue, @"");

		owner.testNonatomicCopyProperty = value;
		STAssertFalse(owner.testNonatomicCopyProperty == value, @"");
		STAssertEqualObjects(owner.testNonatomicCopyProperty, value, @"");

		owner.testAtomicCopyProperty = value;
		STAssertFalse(owner.testAtomicCopyProperty == value, @"");
		STAssertEqualObjects(owner.testAtomicCopyProperty, value, @"");
	}

	STAssertNil(weakValue, @"");
	STAssertEqualObjects(owner.testNonatomicCopyProperty, @"foobar", @"");
	STAssertEqualObjects(owner.testAtomicCopyProperty, @"foobar", @"");
}

- (void)testMultiplePropertiesUsage {
	NSObject *owner = [[NSObject alloc] init];

	id value1 = [@"foobar" mutableCopy];
	id value2 = [@"bardoo" mutableCopy];

	owner.testNonatomicRetainProperty = value1;
	STAssertEqualObjects(owner.testNonatomicRetainProperty, value1, @"");

	owner.testAtomicRetainProperty = value2;
	STAssertEqualObjects(owner.testAtomicRetainProperty, value2, @"");

	STAssertEqualObjects(owner.testNonatomicRetainProperty, value1, @"");
	STAssertEqualObjects(owner.testAtomicRetainProperty, value2, @"");
}

@end
