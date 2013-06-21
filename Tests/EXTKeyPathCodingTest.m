//
//  EXTKeyPathCodingTest.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 19.06.12.
//
//

#import "EXTKeyPathCodingTest.h"

// used to test refactoring also updating @keypath() uses
@interface MyClass : NSObject

+ (BOOL)classProperty;

@property (nonatomic, assign) NSUInteger someUniqueProperty;
@property (nonatomic, copy) NSArray *collection;

@end

@implementation EXTKeyPathCodingTest

- (void)testSingleKey {
    NSURL *URL = [NSURL URLWithString:@"http://www.google.com:8080/search?q=foo"];
    STAssertNotNil(URL, @"");

    NSString *path = @keypath(URL.port);
    STAssertEqualObjects(path, @"port", @"");
}

- (void)testKeyPath {
    NSURL *URL = [NSURL URLWithString:@"http://www.google.com:8080/search?q=foo"];
    STAssertNotNil(URL, @"");

    NSString *path = @keypath(URL.port.stringValue);
    STAssertEqualObjects(path, @"port.stringValue", @"");

    path = @keypath(URL.port, stringValue);
    STAssertEqualObjects(path, @"stringValue", @"");
}

- (void)testClassKeyPath {
    NSString *path = @keypath(NSString.class.description);
    STAssertEqualObjects(path, @"class.description", @"");

    path = @keypath(NSString.class, description);
    STAssertEqualObjects(path, @"description", @"");
}

- (void)testMyClassInstanceKeyPath {
    NSString *path = @keypath(MyClass.new, someUniqueProperty);
    STAssertEqualObjects(path, @"someUniqueProperty", @"");

    MyClass *obj = [[MyClass alloc] init];

    path = @keypath(obj.someUniqueProperty);
    STAssertEqualObjects(path, @"someUniqueProperty", @"");
}

- (void)testMyClassClassKeyPath {
    NSString *path = @keypath(MyClass, classProperty);
    STAssertEqualObjects(path, @"classProperty", @"");
}

- (void)testCollectionInstanceKeyPath {
	MyClass *obj = [[MyClass alloc] init];
	NSString *path = @collectionKeypath(obj.collection, MyClass.new, someUniqueProperty);
	STAssertEqualObjects(path, @"collection.someUniqueProperty", @"");
}

- (void)testCollectionClassKeyPath {
	NSString *path = @collectionKeypath(MyClass.new, collection, MyClass.new, someUniqueProperty);
	STAssertEqualObjects(path, @"collection.someUniqueProperty", @"");
}

@end

@implementation MyClass
@synthesize someUniqueProperty;

+ (BOOL)classProperty {
	return NO;
}

@end
