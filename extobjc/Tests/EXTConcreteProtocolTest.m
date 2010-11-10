//
//  EXTConcreteProtocolTest.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 2010-11-09.
//  Released into the public domain.
//

#import "EXTConcreteProtocolTest.h"

@concreteprotocol(MyProtocol)
+ (NSUInteger)meaningfulNumber {
	return 42;
}

- (NSString *)getSomeString {
  	return @"MyProtocol";
}

@end

@interface TestClass : NSObject <MyProtocol> {}
@end

@implementation TestClass
+ (NSUInteger)meaningfulNumber {
 	return 0;
}
@end

@interface TestClass2 : NSObject <MyProtocol> {}
@end

@implementation TestClass2
- (NSString *)getSomeString {
  	return @"TestClass2";
}
@end

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

@end
