//
//  EXTFinalMethodTest.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-03-02.
//  Copyright (C) 2012 Justin Spahr-Summers.
//  Released under the MIT license.
//

#import "EXTFinalMethodTest.h"

/*** test class interfaces ***/
@interface MySuperclass : NSObject {}
@end

@interface MySubclass : MySuperclass {}
@end

/*** test class implementations ***/
@final (MySuperclass)
- (Class)superclassFinalMethod;
+ (Class)superclassFinalClassMethod;
@endfinal

@implementation MySuperclass
- (Class)superclassFinalMethod {
    return [MySuperclass class];
}

+ (Class)superclassFinalClassMethod {
    return [MySuperclass class];
}

- (Class)normalMethod {
    return nil;
}
@end

@final (MySubclass)
+ (void)subclassFinalClassMethod;
@endfinal

@implementation MySubclass
// this should log an error to the console
- (Class)superclassFinalMethod {
    return [MySubclass class];
}

// this should log an error to the console
+ (Class)superclassFinalClassMethod {
    return [MySubclass class];
}

+ (void)subclassFinalClassMethod {}

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

    STAssertEqualObjects([MySuperclass superclassFinalClassMethod], [MySuperclass class], @"could not call final class method on superclass");
    STAssertNoThrow([MySubclass subclassFinalClassMethod], @"could not call final class method on a subclass");

    MySubclass *subObj = [[MySubclass alloc] init];
    STAssertNotNil(subObj, @"could not allocate instance of subclass containing final methods");
    STAssertEqualObjects([subObj normalMethod], [MySubclass class], @"expected normal method to work in a subclass with final methods");
}

@end
