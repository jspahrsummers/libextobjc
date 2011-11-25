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

@end

@implementation RuntimeTestClass
@synthesize array = m_array;
@synthesize normalString;
@end

@implementation EXTRuntimeExtensionsTest
- (void)testPropertyAttributes {
    {
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

        free(attributes);
    }

    {
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

        free(attributes);
    }
}
@end
