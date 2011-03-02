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
#if 0
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
}

@end
