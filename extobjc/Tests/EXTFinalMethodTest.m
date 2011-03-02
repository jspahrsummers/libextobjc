//
//  EXTFinalMethodTest.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-03-02.
//  Released into the public domain.
//

#import "EXTFinalMethodTest.h"

/*** test class interfaces ***/
@interface MySuperclass : NSObject {}
// should return MySuperclass
- (Class)superclassFinalMethod;

// returns nil here
- (Class)normalMethod;
@end

@interface MySubclass : MySuperclass {}
+ (void)subclassFinalMethod;

// returns the current class (MySubclass) here
- (Class)normalMethod;
@end

/*** test class implementations ***/
@implementation MySuperclass
finalInstanceMethod(MySuperclass, superclassFinalMethod);

- (Class)superclassFinalMethod {
  	return [MySuperclass class];
}

- (Class)normalMethod {
  	return nil;
}
@end

@implementation MySubclass
finalClassMethod(MySubclass, subclassFinalMethod);

// enable to test the erroring out at startup
#if 1
- (Class)superclassFinalMethod {
	return [MySubclass class];
}
#endif

+ (void)subclassFinalMethod {}

- (Class)normalMethod {
 	return [self class];
}
@end

@implementation EXTFinalMethodTest

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testFinalMethods {
	MySuperclass *superObj = [[MySuperclass alloc] init];
	STAssertNotNil(superObj, @"could not allocate instance of class containing final methods");
	STAssertEqualObjects([superObj superclassFinalMethod], [MySuperclass class], @"could not call final instance method on a superclass");
	STAssertNil([superObj normalMethod], @"expected normal method to work in a class with final methods");
	STAssertNoThrow([superObj release], @"could not release instance of class containing final methods");

	STAssertNoThrow([MySubclass subclassFinalMethod], @"could not call final class method on a subclass");

	MySubclass *subObj = [[MySubclass alloc] init];
	STAssertNotNil(subObj, @"could not allocate instance of subclass containing final methods");
	STAssertEqualObjects([subObj normalMethod], [MySubclass class], @"expected normal method to work in a subclass with final methods");
	STAssertNoThrow([subObj release], @"could not release instance of subclass containing final methods");
}

@end
