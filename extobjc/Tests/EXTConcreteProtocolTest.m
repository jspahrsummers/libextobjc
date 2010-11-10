//
//  EXTConcreteProtocolTest.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 2010-11-09.
//  Released into the public domain.
//

#import "EXTConcreteProtocolTest.h"

@concreteprotocol(MyProtocol)
- (void)doSomethingInteresting {
  	NSLog(@"this is interesting!");
}
@end

@interface TestClass : NSObject <MyProtocol> {}
@end

@implementation TestClass
@end

@implementation EXTConcreteProtocolTest
- (void)testImplementations {
  	id<MyProtocol> obj = [[TestClass alloc] init];
	[obj doSomethingInteresting];
	[obj release];
}

@end
