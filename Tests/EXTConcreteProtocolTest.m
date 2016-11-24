//
//  EXTConcreteProtocolTest.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 2010-11-09.
//  Copyright (C) 2012 Justin Spahr-Summers.
//  Released under the MIT license.
//

#import "EXTConcreteProtocolTest.h"

static BOOL MyProtocolInitialized = NO;
static BOOL SubProtocolInitialized = NO;

/*** MyProtocol ***/
@concreteprotocol(MyProtocol)
+ (void)initialize {
    NSAssert(!MyProtocolInitialized, @"+initialize should only be invoked once per concrete protocol");
    MyProtocolInitialized = YES;
}

+ (NSUInteger)meaningfulNumber {
    return 42;
}

- (NSString *)getSomeString {
    return @"MyProtocol";
}

@end

/*** SubProtocol ***/
@concreteprotocol(SubProtocol)
+ (void)initialize {
    NSAssert(!SubProtocolInitialized, @"+initialize should only be invoked once per concrete protocol");
    SubProtocolInitialized = YES;
}

- (void)additionalMethod {}

// this should take precedence over the implementation in MyProtocol
- (NSString *)getSomeString {
    return @"SubProtocol";
}
@end

/*** first test class ***/
// conforms to MyProtocol, implements a class method
@interface TestClass : NSObject <MyProtocol> {}
@end

@implementation TestClass
+ (NSUInteger)meaningfulNumber {
    return 0;
}
@end

/*** second test class ***/
// conforms to MyProtocol, implements an instance method
@interface TestClass2 : NSObject <MyProtocol> {}
@end

@implementation TestClass2
- (NSString *)getSomeString {
    return @"TestClass2";
}
@end

/*** third test class ***/
// conforms to SubProtocol (a child of MyProtocol), implements a class
// method from MyProtocol
@interface TestClass3 : NSObject <SubProtocol> {}
@end

@implementation TestClass3
+ (NSUInteger)meaningfulNumber {
    return 0;
}
@end

/*** fourth test class ***/
// inherits from TestClass3 and doesn't indicate conformance to its protocols
@interface TestClass4 : TestClass3 {}
@end

@implementation TestClass4
@end

/*** fifth test class ***/
// inherits from TestClass (thus conforming to MyProtocol implicitly) and
// conforms to SubProtocol
@interface TestClass5 : TestClass <SubProtocol> {}
@end

@implementation TestClass5
@end

// Classes for deeper test of preservation of inheritance
@interface BaseA : NSObject
@end
@implementation BaseA
- (int)callMeMaybe {return 1;}
@end

@protocol CallMeMaybeType <NSObject>
@concrete
- (int)callMeMaybe;
@end
@concreteprotocol(CallMeMaybeType)
- (int)callMeMaybe {return 20;}
@end

@interface AOverride : BaseA <CallMeMaybeType>
@end
@implementation AOverride
- (int)callMeMaybe {return 300;}
@end

@interface ASuper : BaseA <CallMeMaybeType>
- (int)otherCallMe;
@end
@implementation ASuper
- (int)otherCallMe {
    return [super callMeMaybe];
}
@end

@interface AConcrete : BaseA <CallMeMaybeType>
@end
@implementation AConcrete
@end

/*** logic test code ***/
@implementation EXTConcreteProtocolTest
- (void)tearDown {
    XCTAssertTrue(MyProtocolInitialized, @"+initialize should have been invoked on MyProtocol");
    XCTAssertTrue(SubProtocolInitialized, @"+initialize should have been invoked on SubProtocol");
}

- (void)testImplementations {
    id<MyProtocol> obj;
    
    obj = [[TestClass alloc] init];
    XCTAssertNotNil(obj, @"could not allocate concreteprotocol'd class");
    XCTAssertEqualObjects([obj getSomeString], @"MyProtocol", @"TestClass should be using protocol implementation of getSomeString");

    obj = [[TestClass2 alloc] init];
    XCTAssertNotNil(obj, @"could not allocate concreteprotocol'd class");
    XCTAssertEqualObjects([obj getSomeString], @"TestClass2", @"TestClass2 should not be using protocol implementation of getSomeString");

    XCTAssertEqual([TestClass meaningfulNumber], (NSUInteger)0, @"TestClass should not be using protocol implementation of meaningfulNumber");
    XCTAssertEqual([TestClass2 meaningfulNumber], (NSUInteger)42, @"TestClass2 should be using protocol implementation of meaningfulNumber");
}

- (void)testSimpleInheritance {
    TestClass3 *obj;

    XCTAssertEqual([TestClass3 meaningfulNumber], (NSUInteger)0, @"TestClass3 should not be using protocol implementation of meaningfulNumber");
    
    obj = [[TestClass3 alloc] init];
    XCTAssertNotNil(obj, @"could not allocate concreteprotocol'd class");
    XCTAssertEqualObjects([obj getSomeString], @"SubProtocol", @"TestClass3 should be using protocol implementation of getSomeString");
    XCTAssertTrue([obj respondsToSelector:@selector(additionalMethod)], @"TestClass3 should have protocol implementation of additionalMethod");

    XCTAssertEqual([TestClass4 meaningfulNumber], (NSUInteger)0, @"TestClass4 should not be using protocol implementation of meaningfulNumber");
    
    obj = [[TestClass4 alloc] init];
    XCTAssertNotNil(obj, @"could not allocate concreteprotocol'd subclass");
    XCTAssertEqualObjects([obj getSomeString], @"SubProtocol", @"TestClass4 should be using protocol implementation of getSomeString");
    XCTAssertTrue([obj respondsToSelector:@selector(additionalMethod)], @"TestClass4 should have protocol implementation of additionalMethod");
}

// protocols have to be injected to all classes in the order of the protocol
// inheritance
// 
// Consider classes X and Y that implement protocols A and B, respectively.
// B needs to get its implementation into Y before A gets into X (which would
// block the injection of B).
- (void)testClassInheritanceWithProtocolInheritance {
    TestClass5 *obj = [[TestClass5 alloc] init];
    XCTAssertNotNil(obj, @"could not allocate concreteprotocol'd class");
    XCTAssertTrue([obj respondsToSelector:@selector(additionalMethod)], @"TestClass5 should have protocol implementation of additionalMethod");
    XCTAssertEqualObjects([obj getSomeString], @"SubProtocol", @"TestClass5 should be using SubProtocol implementation of getSomeString");

    XCTAssertEqual([TestClass5 meaningfulNumber], (NSUInteger)0, @"TestClass5 should not be using protocol implementation of meaningfulNumber");
}

- (void)testInheritanceChain
{
    AOverride *aOverride = [[AOverride alloc] init];
    STAssertNotNil(aOverride, @"could not allocate concreteprotocol'd class");
    STAssertEquals([aOverride callMeMaybe], (NSInteger)300, @"aOverride should not be using protocol implementation of callMeMaybe");
    
    ASuper *aSuper = [[ASuper alloc] init];
    STAssertNotNil(aSuper, @"could not allocate concreteprotocol'd class");
    STAssertEquals([aSuper otherCallMe], (NSInteger)1, @"aSuper should not be using protocol implementation of callMeMaybe, but should be using superclass definition.");
    
    AConcrete *aConcrete = [[AConcrete alloc] init];
    STAssertNotNil(aConcrete, @"could not allocate concreteprotocol'd class");
    STAssertEquals([aConcrete callMeMaybe], (NSInteger)20, @"aConcrete should not be using protocol implementation of callMeMaybe, but should be using superclass definition.");
}

@end
