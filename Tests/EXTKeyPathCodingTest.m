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

- (void)testClassInstanceKeyPath {
    NSString *path = @keypathClassInstance(NSString, hash);
    STAssertEqualObjects(path, @"hash", @"");
    
    path = @keypathClassInstance(NSError, domain, hash);
    STAssertEqualObjects(path, @"hash", @"");
    
    path = @keypathClassInstance(NSError, domain.hash);
    STAssertEqualObjects(path, @"domain.hash", @"");
    
    path = @keypathClassInstance(MyClass, someUniqueProperty);
    STAssertEqualObjects(path, @"someUniqueProperty", @"");
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

@end

@implementation MyClass
@synthesize someUniqueProperty;

+ (BOOL)classProperty {
	return NO;
}

@end
