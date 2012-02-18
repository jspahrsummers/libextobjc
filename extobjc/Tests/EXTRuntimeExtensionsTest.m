//
//  EXTRuntimeExtensionsTest.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-03-06.
//  Released into the public domain.
//

#import "EXTRuntimeExtensionsTest.h"

@interface RuntimeTestClass : NSObject {
}

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

@implementation EXTRuntimeExtensionsTest

- (void)testPropertyAttributesForBOOL {
    objc_property_t property = class_getProperty([RuntimeTestClass class], "normalBool");
    NSLog(@"property attributes: %s", property_getAttributes(property));

    ext_propertyAttributes *attributes = ext_copyPropertyAttributes(property);
    STAssertTrue(attributes != NULL, @"could not get property attributes");

    STAssertEquals(attributes->readonly, YES, @"");
    STAssertEquals(attributes->nonatomic, YES, @"");
    STAssertEquals(attributes->weak, NO, @"");
    STAssertEquals(attributes->canBeCollected, NO, @"");
    STAssertEquals(attributes->dynamic, NO, @"");
    STAssertEquals(attributes->memoryManagementPolicy, ext_propertyMemoryManagementPolicyAssign, @"");

    STAssertEquals(attributes->getter, @selector(isNormalBool), @"");
    STAssertEquals(attributes->setter, @selector(setNormalBool:), @"");

    STAssertTrue(strcmp(attributes->ivar, "_normalBool") == 0, @"expected property ivar name to be '_normalBool'");
    STAssertTrue(strlen(attributes->type) > 0, @"property type is missing from attributes");

    NSUInteger size = 0;
    NSGetSizeAndAlignment(attributes->type, &size, NULL);
    STAssertTrue(size > 0, @"invalid property type %s, has no size", attributes->type);

    STAssertNil(attributes->objectClass, @"");

    free(attributes);
}

- (void)testPropertyAttributesForArray {
    objc_property_t property = class_getProperty([RuntimeTestClass class], "array");
    NSLog(@"property attributes: %s", property_getAttributes(property));

    ext_propertyAttributes *attributes = ext_copyPropertyAttributes(property);
    STAssertTrue(attributes != NULL, @"could not get property attributes");

    STAssertEquals(attributes->readonly, NO, @"");
    STAssertEquals(attributes->nonatomic, YES, @"");
    STAssertEquals(attributes->weak, NO, @"");
    STAssertEquals(attributes->canBeCollected, NO, @"");
    STAssertEquals(attributes->dynamic, NO, @"");
    STAssertEquals(attributes->memoryManagementPolicy, ext_propertyMemoryManagementPolicyRetain, @"");

    STAssertEquals(attributes->getter, @selector(whoopsWhatArray), @"");
    STAssertEquals(attributes->setter, @selector(setThatArray:), @"");

    STAssertTrue(strcmp(attributes->ivar, "m_array") == 0, @"expected property ivar name to be 'm_array'");
    STAssertTrue(strlen(attributes->type) > 0, @"property type is missing from attributes");

    NSUInteger size = 0;
    NSGetSizeAndAlignment(attributes->type, &size, NULL);
    STAssertTrue(size > 0, @"invalid property type %s, has no size", attributes->type);

    STAssertEqualObjects(attributes->objectClass, [NSArray class], @"");

    free(attributes);
}

- (void)testPropertyAttributesForNormalString {
    objc_property_t property = class_getProperty([RuntimeTestClass class], "normalString");
    NSLog(@"property attributes: %s", property_getAttributes(property));

    ext_propertyAttributes *attributes = ext_copyPropertyAttributes(property);
    STAssertTrue(attributes != NULL, @"could not get property attributes");

    STAssertEquals(attributes->readonly, NO, @"");
    STAssertEquals(attributes->nonatomic, NO, @"");
    STAssertEquals(attributes->weak, NO, @"");
    STAssertEquals(attributes->canBeCollected, NO, @"");
    STAssertEquals(attributes->dynamic, NO, @"");
    STAssertEquals(attributes->memoryManagementPolicy, ext_propertyMemoryManagementPolicyCopy, @"");

    STAssertEquals(attributes->getter, @selector(normalString), @"");
    STAssertEquals(attributes->setter, @selector(setNormalString:), @"");

    STAssertTrue(strcmp(attributes->ivar, "normalString") == 0, @"expected property ivar name to match the name of the property");
    STAssertTrue(strlen(attributes->type) > 0, @"property type is missing from attributes");

    NSUInteger size = 0;
    NSGetSizeAndAlignment(attributes->type, &size, NULL);
    STAssertTrue(size > 0, @"invalid property type %s, has no size", attributes->type);

    STAssertEqualObjects(attributes->objectClass, [NSString class], @"");

    free(attributes);
}

- (void)testPropertyAttributesForUntypedObject {
    objc_property_t property = class_getProperty([RuntimeTestClass class], "untypedObject");
    NSLog(@"property attributes: %s", property_getAttributes(property));

    ext_propertyAttributes *attributes = ext_copyPropertyAttributes(property);
    STAssertTrue(attributes != NULL, @"could not get property attributes");

    STAssertEquals(attributes->readonly, NO, @"");
    STAssertEquals(attributes->nonatomic, NO, @"");
    STAssertEquals(attributes->weak, NO, @"");
    STAssertEquals(attributes->canBeCollected, NO, @"");
    STAssertEquals(attributes->dynamic, YES, @"");
    STAssertEquals(attributes->memoryManagementPolicy, ext_propertyMemoryManagementPolicyAssign, @"");

    STAssertEquals(attributes->getter, @selector(untypedObject), @"");
    STAssertEquals(attributes->setter, @selector(setUntypedObject:), @"");

    STAssertTrue(attributes->ivar == NULL, @"untypedObject property should not have a backing ivar");
    STAssertTrue(strlen(attributes->type) > 0, @"property type is missing from attributes");

    NSUInteger size = 0;
    NSGetSizeAndAlignment(attributes->type, &size, NULL);
    STAssertTrue(size > 0, @"invalid property type %s, has no size", attributes->type);

    // cannot get class for type 'id'
    STAssertNil(attributes->objectClass, @"");

    free(attributes);
}

- (void)testPropertyAttributesForWeakObject {
    objc_property_t property = class_getProperty([RuntimeTestClass class], "weakObject");
    NSLog(@"property attributes: %s", property_getAttributes(property));

    ext_propertyAttributes *attributes = ext_copyPropertyAttributes(property);
    STAssertTrue(attributes != NULL, @"could not get property attributes");

    STAssertEquals(attributes->readonly, NO, @"");
    STAssertEquals(attributes->nonatomic, YES, @"");
    STAssertEquals(attributes->weak, YES, @"");
    STAssertEquals(attributes->canBeCollected, NO, @"");
    STAssertEquals(attributes->dynamic, NO, @"");
    STAssertEquals(attributes->memoryManagementPolicy, ext_propertyMemoryManagementPolicyAssign, @"");

    STAssertEquals(attributes->getter, @selector(weakObject), @"");
    STAssertEquals(attributes->setter, @selector(setWeakObject:), @"");

    STAssertTrue(attributes->ivar == NULL, @"weakObject property should not have a backing ivar");
    STAssertTrue(strlen(attributes->type) > 0, @"property type is missing from attributes");

    NSUInteger size = 0;
    NSGetSizeAndAlignment(attributes->type, &size, NULL);
    STAssertTrue(size > 0, @"invalid property type %s, has no size", attributes->type);

    STAssertEqualObjects(attributes->objectClass, [NSObject class], @"");

    free(attributes);
}

@end
