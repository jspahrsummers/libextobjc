//
//  EXTPrivateMethodTest.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-03-02.
//  Released into the public domain.
//

#import "EXTPrivateMethodTest.h"

/*** test superclass ***/
@interface PrivateTestClass : NSURLRequest {
}

+ (float)classStuff;
- (int)stuff;

@end

@private (PrivateTestClass)
+ (float)privateClassValue;
- (int)privateValue;
@endprivate

@implementation PrivateTestClass
+ (float)classStuff {
	return [privateSelf privateClassValue];
}

+ (float)privateClassValue {
	return 3.14f;
}

- (int)stuff {
  	return [privateSelf privateValue];
}

- (int)privateValue {
	return 42;
}
@end

/*** test subclass ***/
@interface PrivateTestSubclass : PrivateTestClass {
}

+ (float)classStuff;
- (int)getValue;
@end

@private (PrivateTestSubclass)
+ (float)privateClassValue;
- (int)privateValue;
@endprivate

@implementation PrivateTestSubclass
+ (float)classStuff {
	return [privateSelf privateClassValue];
}

+ (float)privateClassValue {
	return -85.24f;
}

- (int)getValue {
  	return [privateSelf privateValue];
}

- (int)privateValue {
	return 1337;
}
@end

@implementation EXTPrivateMethodTest
- (void)testBasicPrivateMethods {
	PrivateTestClass *obj = [[PrivateTestClass alloc] init];

	STAssertNotNil(obj, @"could not allocate instance of class with private methods");
	STAssertEquals([obj stuff], 42, @"expected -[PrivateTestClass stuff] to return 42");
	STAssertEqualsWithAccuracy([PrivateTestClass classStuff], 3.14f, 0.01f, @"expected +[PrivateTestClass classStuff] to return 3.14");
	STAssertNoThrow([obj release], @"could not deallocate instance of class with private methods");
}

- (void)testPrivateMethodInheritance {
	PrivateTestSubclass *obj = [[PrivateTestSubclass alloc] init];

	STAssertNotNil(obj, @"could not allocate instance of subclass with private methods");
	STAssertEquals([obj stuff], 42, @"expected -[PrivateTestSubclass stuff] to return 42");
	STAssertEquals([obj getValue], 1337, @"expected -[PrivateTestSubclass getValue] to return 1337");
	STAssertEqualsWithAccuracy([PrivateTestSubclass classStuff], -85.24f, 0.01f, @"expected +[PrivateTestSubclass classStuff] to return -85.24");
	STAssertNoThrow([obj release], @"could not deallocate instance of subclass with private methods");
}
@end
