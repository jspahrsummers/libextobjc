//
//  EXTBlockMethodTest.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-03-20.
//  Copyright (C) 2012 Justin Spahr-Summers.
//  Released under the MIT license.
//

#import "EXTBlockMethodTest.h"

@interface BlockTestClass : NSObject {}
- (NSString *)testDescription;
@end

@implementation BlockTestClass
- (NSString *)testDescription {
    return @"method";
}

@end

@interface BlockTestClass (TypeInformationExtension)
- (int)multiplyByTwo:(int)value;
@end

@interface BlockTestSubclass : BlockTestClass {}
@end

@implementation BlockTestSubclass
@end

@implementation EXTBlockMethodTest
- (void)testAddingMethod {
    id block = ^(id self, int val){
			
        XCTAssertTrue([self isKindOfClass:[BlockTestClass class]], @"expected self to be an instance of BlockTestClass or one of its subclasses");
        return val * 2;
    };

	
    XCTAssertNotNil(block, @"could not get block method");

    BOOL success = ext_addBlockMethod(
        [BlockTestClass class],
        @selector(multiplyByTwo:),
        block,

        // hardcoded just for testing
        // this should map to:
        //     int impl (id self, SEL _cmd, int val);
        "i@:i"
    );

	
    XCTAssertTrue(success, @"could not add new block method to BlockTestClass");

    {
        BlockTestClass *obj = [[BlockTestClass alloc] init];
			
        XCTAssertNotNil(obj, @"could not allocate BlockTestClass instance");

        int expected = 84;

        int result;
			
        XCTAssertNoThrow(result = [obj multiplyByTwo:42], @"expected -multiplyByTwo: method to be available");
        XCTAssertEqual(expected, result, @"expected -multiplyByTwo: method to be implemented using block implementation");
    }

    {
        BlockTestSubclass *obj = [[BlockTestSubclass alloc] init];
        XCTAssertNotNil(obj, @"could not allocate BlockTestSubclass instance");

        int expected = 84;

        int result;
			
        XCTAssertNoThrow(result = [obj multiplyByTwo:42], @"expected -multiplyByTwo: method to be available");
        XCTAssertEqual(expected, result, @"expected -multiplyByTwo: method to be implemented using block implementation");
    }
}

- (void)testReplacingMethod {
    BlockTestClass *obj = [[BlockTestClass alloc] init];
    XCTAssertNotNil(obj, @"could not allocate BlockTestClass instance");

    XCTAssertEqualObjects([obj testDescription], @"method", @"expected -testDescription before replacement to be as defined in BlockTestClass");

    BlockTestSubclass *subobj = [[BlockTestSubclass alloc] init];
    XCTAssertNotNil(subobj, @"could not allocate BlockTestSubclass instance");

    XCTAssertEqualObjects([subobj testDescription], @"method", @"expected -testDescription before replacement to be as defined in BlockTestClass");

    __block BOOL testDescriptionCalled = NO;

    id block = ^ id (id self){
        if ([self isMemberOfClass:[BlockTestClass class]]) {
            testDescriptionCalled = YES;
            return @"block";
        } else if ([self isMemberOfClass:[BlockTestSubclass class]]) {
            return @"subclass";
        } else {
            XCTFail(@"expected self to be an instance of BlockTestClass or BlockTestSubclass");
            return nil;
        }
    };

    Class cls = [BlockTestClass class];
    SEL name = @selector(testDescription);

    ext_replaceBlockMethod(
        cls,
        @selector(testDescription),
        block,
        method_getTypeEncoding(class_getInstanceMethod(cls, name))
    );

	
    XCTAssertFalse(testDescriptionCalled, @"expected -testDescription replacement to not yet be invoked");
	
    XCTAssertEqualObjects([obj testDescription], @"block", @"expected -testDescription after replacement to be as defined in block");
	
    XCTAssertTrue(testDescriptionCalled, @"expected -testDescription replacement to have been invoked and update context");
	
		XCTAssertEqualObjects([subobj testDescription], @"subclass", @"expected -testDescription after replacement to be as defined in block");
}
@end
