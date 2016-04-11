//
//  EXTRuntimeExtensionsTest.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-03-06.
//  Copyright (C) 2012 Justin Spahr-Summers.
//  Released under the MIT license.
//

#import "EXTRuntimeExtensionsTest.h"
#import "EXTRuntimeTestProtocol.h"
#import "NSMethodSignature+EXT.h"

#pragma mark - RuntimeTestClass

@interface RuntimeTestClass : NSObject <EXTRuntimeTestProtocol>

@property (nonatomic, assign, getter = isNormalBool, readonly) BOOL normalBool;
@property (nonatomic, strong, getter = whoopsWhatArray, setter = setThatArray:) NSArray *array;
@property (copy) NSString *normalString;
@property (unsafe_unretained) id untypedObject;
@property (nonatomic, weak) NSObject *weakObject;

@end

@implementation RuntimeTestClass
@synthesize normalBool = _normalBool;
@synthesize array = m_array;
@synthesize normalString;

- (NSObject *)weakObject {
    return nil;
}

- (void)setWeakObject:(NSObject *)weakObject {
}

@dynamic untypedObject;
@end

#pragma mark - Tests

@implementation EXTRuntimeExtensionsTest

- (void)testPropertyAttributesForBOOL {
    objc_property_t property = class_getProperty([RuntimeTestClass class], "normalBool");
    NSLog(@"property attributes: %s", property_getAttributes(property));

    ext_propertyAttributes *attributes = ext_copyPropertyAttributes(property);
    XCTAssertTrue(attributes != NULL, @"could not get property attributes");

    XCTAssertEqual(attributes->readonly, YES, @"");
    XCTAssertEqual(attributes->nonatomic, YES, @"");
    XCTAssertEqual(attributes->weak, NO, @"");
    XCTAssertEqual(attributes->canBeCollected, NO, @"");
    XCTAssertEqual(attributes->dynamic, NO, @"");
    XCTAssertEqual(attributes->memoryManagementPolicy, ext_propertyMemoryManagementPolicyAssign, @"");

    XCTAssertEqual(attributes->getter, @selector(isNormalBool), @"");
    XCTAssertEqual(attributes->setter, @selector(setNormalBool:), @"");

    XCTAssertTrue(strcmp(attributes->ivar, "_normalBool") == 0, @"expected property ivar name to be '_normalBool'");
    XCTAssertTrue(strlen(attributes->type) > 0, @"property type is missing from attributes");

    NSUInteger size = 0;
    NSGetSizeAndAlignment(attributes->type, &size, NULL);
    XCTAssertTrue(size > 0, @"invalid property type %s, has no size", attributes->type);

    XCTAssertNil(attributes->objectClass, @"");

    free(attributes);
}

- (void)testPropertyAttributesForArray {
    objc_property_t property = class_getProperty([RuntimeTestClass class], "array");
    NSLog(@"property attributes: %s", property_getAttributes(property));

    ext_propertyAttributes *attributes = ext_copyPropertyAttributes(property);
    XCTAssertTrue(attributes != NULL, @"could not get property attributes");

    XCTAssertEqual(attributes->readonly, NO, @"");
    XCTAssertEqual(attributes->nonatomic, YES, @"");
    XCTAssertEqual(attributes->weak, NO, @"");
    XCTAssertEqual(attributes->canBeCollected, NO, @"");
    XCTAssertEqual(attributes->dynamic, NO, @"");
    XCTAssertEqual(attributes->memoryManagementPolicy, ext_propertyMemoryManagementPolicyRetain, @"");

    XCTAssertEqual(attributes->getter, @selector(whoopsWhatArray), @"");
    XCTAssertEqual(attributes->setter, @selector(setThatArray:), @"");

    XCTAssertTrue(strcmp(attributes->ivar, "m_array") == 0, @"expected property ivar name to be 'm_array'");
    XCTAssertTrue(strlen(attributes->type) > 0, @"property type is missing from attributes");

    NSUInteger size = 0;
    NSGetSizeAndAlignment(attributes->type, &size, NULL);
    XCTAssertTrue(size > 0, @"invalid property type %s, has no size", attributes->type);

    XCTAssertEqualObjects(attributes->objectClass, [NSArray class], @"");

    free(attributes);
}

- (void)testPropertyAttributesForNormalString {
    objc_property_t property = class_getProperty([RuntimeTestClass class], "normalString");
    NSLog(@"property attributes: %s", property_getAttributes(property));

    ext_propertyAttributes *attributes = ext_copyPropertyAttributes(property);
    XCTAssertTrue(attributes != NULL, @"could not get property attributes");

    XCTAssertEqual(attributes->readonly, NO, @"");
    XCTAssertEqual(attributes->nonatomic, NO, @"");
    XCTAssertEqual(attributes->weak, NO, @"");
    XCTAssertEqual(attributes->canBeCollected, NO, @"");
    XCTAssertEqual(attributes->dynamic, NO, @"");
    XCTAssertEqual(attributes->memoryManagementPolicy, ext_propertyMemoryManagementPolicyCopy, @"");

    XCTAssertEqual(attributes->getter, @selector(normalString), @"");
    XCTAssertEqual(attributes->setter, @selector(setNormalString:), @"");

    XCTAssertTrue(strcmp(attributes->ivar, "normalString") == 0, @"expected property ivar name to match the name of the property");
    XCTAssertTrue(strlen(attributes->type) > 0, @"property type is missing from attributes");

    NSUInteger size = 0;
    NSGetSizeAndAlignment(attributes->type, &size, NULL);
    XCTAssertTrue(size > 0, @"invalid property type %s, has no size", attributes->type);

    XCTAssertEqualObjects(attributes->objectClass, [NSString class], @"");

    free(attributes);
}

- (void)testPropertyAttributesForUntypedObject {
    objc_property_t property = class_getProperty([RuntimeTestClass class], "untypedObject");
    NSLog(@"property attributes: %s", property_getAttributes(property));

    ext_propertyAttributes *attributes = ext_copyPropertyAttributes(property);
    XCTAssertTrue(attributes != NULL, @"could not get property attributes");

    XCTAssertEqual(attributes->readonly, NO, @"");
    XCTAssertEqual(attributes->nonatomic, NO, @"");
    XCTAssertEqual(attributes->weak, NO, @"");
    XCTAssertEqual(attributes->canBeCollected, NO, @"");
    XCTAssertEqual(attributes->dynamic, YES, @"");
    XCTAssertEqual(attributes->memoryManagementPolicy, ext_propertyMemoryManagementPolicyAssign, @"");

    XCTAssertEqual(attributes->getter, @selector(untypedObject), @"");
    XCTAssertEqual(attributes->setter, @selector(setUntypedObject:), @"");

    XCTAssertTrue(attributes->ivar == NULL, @"untypedObject property should not have a backing ivar");
    XCTAssertTrue(strlen(attributes->type) > 0, @"property type is missing from attributes");

    NSUInteger size = 0;
    NSGetSizeAndAlignment(attributes->type, &size, NULL);
    XCTAssertTrue(size > 0, @"invalid property type %s, has no size", attributes->type);

    // cannot get class for type 'id'
    XCTAssertNil(attributes->objectClass, @"");

    free(attributes);
}

- (void)testPropertyAttributesForWeakObject {
    objc_property_t property = class_getProperty([RuntimeTestClass class], "weakObject");
    NSLog(@"property attributes: %s", property_getAttributes(property));

    ext_propertyAttributes *attributes = ext_copyPropertyAttributes(property);
    XCTAssertTrue(attributes != NULL, @"could not get property attributes");

    XCTAssertEqual(attributes->readonly, NO, @"");
    XCTAssertEqual(attributes->nonatomic, YES, @"");
    XCTAssertEqual(attributes->weak, YES, @"");
    XCTAssertEqual(attributes->canBeCollected, NO, @"");
    XCTAssertEqual(attributes->dynamic, NO, @"");
    XCTAssertEqual(attributes->memoryManagementPolicy, ext_propertyMemoryManagementPolicyAssign, @"");

    XCTAssertEqual(attributes->getter, @selector(weakObject), @"");
    XCTAssertEqual(attributes->setter, @selector(setWeakObject:), @"");

    XCTAssertTrue(attributes->ivar == NULL, @"weakObject property should not have a backing ivar");
    XCTAssertTrue(strlen(attributes->type) > 0, @"property type is missing from attributes");

    NSUInteger size = 0;
    NSGetSizeAndAlignment(attributes->type, &size, NULL);
    XCTAssertTrue(size > 0, @"invalid property type %s, has no size", attributes->type);

    XCTAssertEqualObjects(attributes->objectClass, [NSObject class], @"");

    free(attributes);
}

- (void)testGlobalMethodSignatureForSelector {
    XCTAssertNotNil(objc_getProtocol("EXTRuntimeTestProtocol"), @"test protocol should be loaded");
    NSMethodSignature *ms = ext_globalMethodSignatureForSelector(@selector(optionalInstanceMethod));
    XCTAssertNotNil(ms, @"unimplemented optional protocol instance method should have a method signature");
    ms = ext_globalMethodSignatureForSelector(@selector(optionalClassMethod));
    XCTAssertNotNil(ms, @"unimplemented optional protocol class method should have a method signature");
}

@end
