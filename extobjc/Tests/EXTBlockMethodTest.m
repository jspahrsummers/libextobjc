//
//  EXTBlockMethodTest.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-03-20.
//  Released into the public domain.
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
        STAssertTrue([self isKindOfClass:[BlockTestClass class]], @"expected self to be an instance of BlockTestClass or one of its subclasses");
        return val * 2;
    };

    STAssertNotNil(block, @"could not get block method");

    BOOL success = ext_addBlockMethod(
        [BlockTestClass class],
        @selector(multiplyByTwo:),
        block,

        // hardcoded just for testing
        // this should map to:
        //     int impl (id self, SEL _cmd, int val);
        "i@:i"
    );

    STAssertTrue(success, @"could not add new block method to BlockTestClass");

    {
        BlockTestClass *obj = [[BlockTestClass alloc] init];
        STAssertNotNil(obj, @"could not allocate BlockTestClass instance");

        int expected = 84;

        int result;
        STAssertNoThrow(result = [obj multiplyByTwo:42], @"expected -multiplyByTwo: method to be available");
        STAssertEquals(expected, result, @"expected -multiplyByTwo: method to be implemented using block implementation");
    }

    {
        BlockTestSubclass *obj = [[BlockTestSubclass alloc] init];
        STAssertNotNil(obj, @"could not allocate BlockTestSubclass instance");

        int expected = 84;

        int result;
        STAssertNoThrow(result = [obj multiplyByTwo:42], @"expected -multiplyByTwo: method to be available");
        STAssertEquals(expected, result, @"expected -multiplyByTwo: method to be implemented using block implementation");
    }
}

- (void)testReplacingMethod {
    BlockTestClass *obj = [[BlockTestClass alloc] init];
    STAssertNotNil(obj, @"could not allocate BlockTestClass instance");

    STAssertEqualObjects([obj testDescription], @"method", @"expected -testDescription before replacement to be as defined in BlockTestClass");

    BlockTestSubclass *subobj = [[BlockTestSubclass alloc] init];
    STAssertNotNil(subobj, @"could not allocate BlockTestSubclass instance");

    STAssertEqualObjects([subobj testDescription], @"method", @"expected -testDescription before replacement to be as defined in BlockTestClass");

    __block BOOL testDescriptionCalled = NO;

    id block = ^(id self){
        if ([self isMemberOfClass:[BlockTestClass class]]) {
            testDescriptionCalled = YES;
            return @"block";
        } else if ([self isMemberOfClass:[BlockTestSubclass class]]) {
            return @"subclass";
        } else {
            STFail(@"expected self to be an instance of BlockTestClass or BlockTestSubclass");
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

    STAssertFalse(testDescriptionCalled, @"expected -testDescription replacement to not yet be invoked");
    STAssertEqualObjects([obj testDescription], @"block", @"expected -testDescription after replacement to be as defined in block");
    STAssertTrue(testDescriptionCalled, @"expected -testDescription replacement to have been invoked and update context");

    STAssertEqualObjects([subobj testDescription], @"subclass", @"expected -testDescription after replacement to be as defined in block");
}
@end
