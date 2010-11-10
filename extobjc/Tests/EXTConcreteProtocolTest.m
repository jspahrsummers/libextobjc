//
//  EXTConcreteProtocolTest.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 2010-11-09.
//  Released into the public domain.
//

#import "EXTConcreteProtocolTest.h"

/*** MyProtocol ***/
@concreteprotocol(MyProtocol)
+ (NSUInteger)meaningfulNumber {
	return 42;
}

- (NSString *)getSomeString {
  	return @"MyProtocol";
}

@end

/*** SubProtocol ***/
@concreteprotocol(SubProtocol)
- (void)additionalMethod {}
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

/*** logic test code ***/
@implementation EXTConcreteProtocolTest
- (void)testImplementations {
  	id<MyProtocol> obj;
	
	obj = [[TestClass alloc] init];
	STAssertNotNil(obj, @"could not allocate concreteprotocol'd class");
	STAssertEqualObjects([obj getSomeString], @"MyProtocol", @"TestClass should be using protocol implementation of getSomeString");
	STAssertNoThrow([obj release], @"could not deallocate concreteprotocol'd class");

	obj = [[TestClass2 alloc] init];
	STAssertNotNil(obj, @"could not allocate concreteprotocol'd class");
	STAssertEqualObjects([obj getSomeString], @"TestClass2", @"TestClass2 should not be using protocol implementation of getSomeString");
	STAssertNoThrow([obj release], @"could not deallocate concreteprotocol'd class");

	STAssertEquals([TestClass meaningfulNumber], (NSUInteger)0, @"TestClass should not be using protocol implementation of meaningfulNumber");
	STAssertEquals([TestClass2 meaningfulNumber], (NSUInteger)42, @"TestClass2 should be using protocol implementation of meaningfulNumber");
}

- (void)testInheritance {
	TestClass3 *obj;

	STAssertEquals([TestClass3 meaningfulNumber], (NSUInteger)0, @"TestClass3 should not be using protocol implementation of meaningfulNumber");
	
	obj = [[TestClass3 alloc] init];
	STAssertNotNil(obj, @"could not allocate concreteprotocol'd class");
	STAssertEqualObjects([obj getSomeString], @"MyProtocol", @"TestClass3 should be using protocol implementation of getSomeString");
	STAssertTrue([obj respondsToSelector:@selector(additionalMethod)], @"TestClass3 should have protocol implementation of additionalMethod");
	STAssertNoThrow([obj release], @"could not deallocate concreteprotocol'd class");

	STAssertEquals([TestClass4 meaningfulNumber], (NSUInteger)0, @"TestClass4 should not be using protocol implementation of meaningfulNumber");
	
	obj = [[TestClass4 alloc] init];
	STAssertNotNil(obj, @"could not allocate concreteprotocol'd subclass");
	STAssertEqualObjects([obj getSomeString], @"MyProtocol", @"TestClass4 should be using protocol implementation of getSomeString");
	STAssertTrue([obj respondsToSelector:@selector(additionalMethod)], @"TestClass4 should have protocol implementation of additionalMethod");
	STAssertNoThrow([obj release], @"could not deallocate concreteprotocol'd subclass");
}

@end
