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
		XCTAssertNotNil(weakValue, @"");

		owner.testNonatomicAssignProperty = value;
		XCTAssertEqual(owner.testNonatomicAssignProperty, value, @"");

		owner.testAtomicAssignProperty = value;
		XCTAssertEqual(owner.testAtomicAssignProperty, value, @"");
	}

	XCTAssertNil(weakValue, @"");
}

- (void)testStrongProperties {
	NSObject *owner = [[NSObject alloc] init];

	__weak id weakValue = nil;

	@autoreleasepool {
		id value __attribute__((objc_precise_lifetime)) = [@"foobar" mutableCopy];

		weakValue = value;
		XCTAssertNotNil(weakValue, @"");

		owner.testNonatomicRetainProperty = value;
		XCTAssertEqual(owner.testNonatomicRetainProperty, value, @"");

		owner.testAtomicRetainProperty = value;
		XCTAssertEqual(owner.testAtomicRetainProperty, value, @"");
	}

	XCTAssertNotNil(weakValue, @"");
	XCTAssertEqual(owner.testNonatomicRetainProperty, weakValue, @"");
	XCTAssertEqual(owner.testAtomicRetainProperty, weakValue, @"");
}

- (void)testCopyProperties {
	NSObject *owner = [[NSObject alloc] init];

	__weak id weakValue = nil;

	@autoreleasepool {
		id value __attribute__((objc_precise_lifetime)) = [@"foobar" mutableCopy];

		weakValue = value;
		XCTAssertNotNil(weakValue, @"");

		owner.testNonatomicCopyProperty = value;
		XCTAssertFalse(owner.testNonatomicCopyProperty == value, @"");
		XCTAssertEqualObjects(owner.testNonatomicCopyProperty, value, @"");

		owner.testAtomicCopyProperty = value;
		XCTAssertFalse(owner.testAtomicCopyProperty == value, @"");
		XCTAssertEqualObjects(owner.testAtomicCopyProperty, value, @"");
	}

	XCTAssertNil(weakValue, @"");
	XCTAssertEqualObjects(owner.testNonatomicCopyProperty, @"foobar", @"");
	XCTAssertEqualObjects(owner.testAtomicCopyProperty, @"foobar", @"");
}

- (void)testMultiplePropertiesUsage {
	NSObject *owner = [[NSObject alloc] init];

	id value1 = [@"foobar" mutableCopy];
	id value2 = [@"bardoo" mutableCopy];

	owner.testNonatomicRetainProperty = value1;
	XCTAssertEqualObjects(owner.testNonatomicRetainProperty, value1, @"");

	owner.testAtomicRetainProperty = value2;
	XCTAssertEqualObjects(owner.testAtomicRetainProperty, value2, @"");

	XCTAssertEqualObjects(owner.testNonatomicRetainProperty, value1, @"");
	XCTAssertEqualObjects(owner.testAtomicRetainProperty, value2, @"");
}

@end
