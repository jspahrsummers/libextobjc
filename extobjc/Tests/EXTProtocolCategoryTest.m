//
//  EXTProtocolCategoryTest.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 2010-11-13.
//  Released into the public domain.
//

#import "EXTProtocolCategoryTest.h"

/*** protocol category ***/
@pcategoryinterface(NSCopying, TestExtensions)
+ (id)duplicateOf:(id<NSCopying>)obj;
@end

@pcategoryimplementation(NSCopying, TestExtensions)
+ (id)duplicateOf:(id<NSCopying>)obj {
	return [[obj copyWithZone:nil] autorelease];
}
@end

/*** logic test code ***/
@implementation EXTProtocolCategoryTest
- (void)testProtocolCategory {
	NSArray *testObjects = [[NSArray alloc] initWithObjects:
		[NSNumber numberWithInt:42],
		[NSArray arrayWithObjects:@"foo", @"bar", nil],
		[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:0xDEADBEEF] forKey:@"deadbeef"],
		nil
	];

	STAssertNotNil(testObjects, @"could not allocate test array of NSCopying objects");
	for (id obj in testObjects) {
		NSAutoreleasePool *pool = [NSAutoreleasePool new];

		STAssertTrue([[obj class] respondsToSelector:@selector(duplicateOf:)], @"class %@ conforming to NSCopying did not respond to category method selector", [obj class]);

		id copiedObj = nil;
		STAssertNoThrow((copiedObj = [[obj class] duplicateOf:obj]), @"could not invoke NSCopying category method on %@", obj);
		STAssertEqualObjects(obj, copiedObj, @"NSCopying category method should've returned a copied object");
		STAssertEqualObjects([[obj copy] autorelease], copiedObj, @"NSCopying category method should've returned a copied object");

		STAssertNoThrow([pool drain], @"error draining autorelease pool containing category'd objects");
	}

	STAssertNoThrow([testObjects release], @"could not deallocate test array of NSCopying objects");
}
@end
