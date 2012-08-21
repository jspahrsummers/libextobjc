//
//  EXTAnnotationTest.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 27.06.12.
//  Copyright (C) 2012 Justin Spahr-Summers.
//  Released under the MIT license.
//

#import "EXTAnnotationTest.h"
#import <objc/runtime.h>

@annotateClass(AnnotatedClass, @"version": @"1.1", @"debug_name": @"EXTAnnotation test class" )
@interface AnnotatedClass : NSObject

@annotate(AnnotatedClass, @"APIKey": @"object_id")
@property (nonatomic, copy) NSString *objectID;

@annotate(AnnotatedClass, @"APIKey": @"full_name", @"other_info": @5)
@property (nonatomic, copy) NSString *name;

@end

@implementation EXTAnnotationTest

- (void)testObjectID {
    NSDictionary *annotations = ext_getPropertyAnnotation([AnnotatedClass class], @"objectID");
    NSDictionary *expected = @{ @"APIKey" : @"object_id" };
    STAssertEqualObjects(annotations, expected, @"");
}

- (void)testName {
    NSDictionary *annotations = ext_getPropertyAnnotation([AnnotatedClass class], @"name");
    NSDictionary *expected = @{ @"APIKey": @"full_name", @"other_info": @5 };
    STAssertEqualObjects(annotations, expected, @"");
}

- (void)testVersion {
    NSDictionary *annotations = ext_getClassAnnotation([AnnotatedClass class]);
    NSDictionary *expected = @{ @"version" : @"1.1", @"debug_name": @"EXTAnnotation test class" };
    STAssertEqualObjects(annotations, expected, @"");
}

@end

@implementation AnnotatedClass
@end
