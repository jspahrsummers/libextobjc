//
//  EXTAnnotationTest.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 27.06.12.
//  Released into the public domain.
//

#import "EXTAnnotationTest.h"
#import <objc/runtime.h>

@interface AnnotatedClass : NSObject

@annotate(AnnotatedClass, @"APIKey": @"object_id")
@property (nonatomic, copy) NSString *objectID;

@annotate(AnnotatedClass, @"APIKey": @"full_name", @"other_info": @5)
@property (nonatomic, copy) NSString *name;

@end

@implementation EXTAnnotationTest

- (void)testObjectID {
    NSDictionary *annotations = ext_getAnnotation([AnnotatedClass class], @"objectID");
    NSDictionary *expected = @{ @"APIKey" : @"object_id" };
    STAssertEqualObjects(annotations, expected, @"");
}

- (void)testName {
    NSDictionary *annotations = ext_getAnnotation([AnnotatedClass class], @"name");
    NSDictionary *expected = @{ @"APIKey": @"full_name", @"other_info": @5 };
    STAssertEqualObjects(annotations, expected, @"");
}

@end

@implementation AnnotatedClass
@end
