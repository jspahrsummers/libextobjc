//
//  EXTSafeCategoryTest.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 2010-11-13.
//  Copyright (C) 2012 Justin Spahr-Summers.
//  Released under the MIT license.
//

#import "EXTSafeCategoryTest.h"

// make sure failed safe categories don't crash the test (since we explicitly
// test such a case below)
#ifndef NDEBUG
#define NDEBUG
#endif

#undef DEBUG

#import "EXTSafeCategory.h"

/*** category interface ***/
@interface NSObject (TestExtensions)
- (NSString *)description;
- (NSString *)customDescription;
@end

/*** category implementation ***/
@safecategory(NSObject, TestExtensions)
- (NSString *)description {
    return [self customDescription];
}

- (NSString *)customDescription {
    return @"NSObject(TestExtensions)";
}

@end

/*** logic test code ***/
@implementation EXTSafeCategoryTest
- (void)testSafeCategory {
    NSObject *obj = [[NSObject alloc] init];
    XCTAssertNotNil(obj, @"could not allocate object of safe category'd class");
    XCTAssertTrue([obj respondsToSelector:@selector(description)], @"category'd object should respond to pre-existing method selector");
    XCTAssertTrue([obj respondsToSelector:@selector(customDescription)], @"category'd object should respond to added method selector");
    XCTAssertFalse([[obj description] isEqualToString:@"NSObject(TestExtensions)"], @"expected -description method to be original implementation, not overriden");
    XCTAssertEqualObjects([obj customDescription], @"NSObject(TestExtensions)", @"expected -customDescription method to be implemented, and return custom value");
}
@end
