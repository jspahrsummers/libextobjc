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

@property (nonatomic, copy, getter = whoopsWhatArray, setter = setThatArray:, readonly) NSArray *array;
@property (copy) NSString *normalString;
@property (unsafe_unretained) id untypedObject;

@end

@implementation RuntimeTestClass
@synthesize array = m_array;
@synthesize normalString;

@dynamic untypedObject;
@end

@implementation EXTRuntimeExtensionsTest
- (void)testPropertyAttributesForArray {
    objc_property_t property = class_getProperty([RuntimeTestClass class], "array");
    NSLog(@"property attributes: %s", property_getAttributes(property));

    ext_propertyAttributes *attributes = ext_copyPropertyAttributes(property);
    STAssertTrue(attributes != NULL, @"could not get property attributes");

    STAssertEquals(attributes->readonly, YES, @"");
    STAssertEquals(attributes->nonatomic, YES, @"");
    STAssertEquals(attributes->weak, NO, @"");
    STAssertEquals(attributes->canBeCollected, NO, @"");

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
@end
