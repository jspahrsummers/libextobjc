//
//  EXTProtocolCategoryTest.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 2010-11-13.
//  Copyright (C) 2012 Justin Spahr-Summers.
//  Released under the MIT license.
//

#import "EXTProtocolCategoryTest.h"

/*** protocol category ***/
@pcategoryinterface(NSCopying, TestExtensions)
+ (id)duplicateOf:(id<NSCopying>)obj;
@end

@pcategoryimplementation(NSCopying, TestExtensions)
+ (id)duplicateOf:(id<NSCopying>)obj {
    return [obj copyWithZone:nil];
}
@end

/*** logic test code ***/
@implementation EXTProtocolCategoryTest
- (void)testProtocolCategory {
    NSArray *testObjects = [[NSArray alloc] initWithObjects:
        @42,
        @[@"foo", @"bar"],
        @{@"deadbeef": @0xDEADBEEF},
        nil
    ];

    STAssertNotNil(testObjects, @"could not allocate test array of NSCopying objects");
    for (id obj in testObjects) {
        STAssertTrue([[obj class] respondsToSelector:@selector(duplicateOf:)], @"class %@ conforming to NSCopying did not respond to category method selector", [obj class]);

        id copiedObj = nil;
        STAssertNoThrow((copiedObj = [[obj class] duplicateOf:obj]), @"could not invoke NSCopying category method on %@", obj);
        STAssertEqualObjects(obj, copiedObj, @"NSCopying category method should've returned a copied object");
        STAssertEqualObjects([obj copy], copiedObj, @"NSCopying category method should've returned a copied object");
    }
}
@end
