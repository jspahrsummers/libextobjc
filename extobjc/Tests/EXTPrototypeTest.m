//
//  EXTPrototypeTest.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-03-12.
//  Released into the public domain.
//

#import "EXTPrototypeTest.h"

@slot(title)
@slot(titleCopy)

@implementation EXTPrototypeTest
- (void)setUp {
	pool = [NSAutoreleasePool new];
}

- (void)tearDown {
	STAssertNoThrow([pool drain], @"");
	pool = nil;
}

- (void)testSimplePrototype {
	EXTPrototype *obj = [EXTPrototype prototype];

	id method = blockMethod(id self){
		NSLog(@"obj: %@ %p", [self class], (void *)self);
		return @"test title";
	};

	obj.title = method;
	STAssertEqualObjects([obj valueForSlot:@"title"], method, @"");

	NSString *title = obj.title;
	STAssertEqualObjects(title, @"test title", @"");

	obj.titleCopy = blockMethod(id self){
		return [self title];
	};

	STAssertEqualObjects(title, obj.titleCopy, @"");
	STAssertEqualObjects(obj.title, obj.titleCopy, @"");
}

- (void)testPrototypeCopying {
	EXTPrototype *orig = [EXTPrototype prototype];
	NSLog(@"orig: %p", (void *)orig);

	orig.title = blockMethod(id self){ return @"test"; };

	STAssertEqualObjects(orig.title, @"test", @"");

	EXTPrototype *copy = [orig copy];
	NSLog(@"copy: %p", (void *)copy);

	STAssertNotNil(copy, @"copy of proto-object should not be nil");

	copy.title = blockMethod(id self){
		//return [[orig class] description];
		return @"test_copy";
		//return orig.title;
		//return [orig.title stringByAppendingString:@"_copy"];
	};

	STAssertEqualObjects(orig.title, @"test", @"");
	STAssertEqualObjects(copy.title, @"test_copy", @"");

	NSLog(@"finished with copy test");
}

- (void)testAddingSetter {
	EXTPrototype *obj = [EXTPrototype prototype];

	__block NSString *objTitle = nil;

	obj.title = blockMethod(id self){ return objTitle; };

	NSString *title = obj.title;
	STAssertNil(title, @"");

	[obj setBlock:blockMethod(id self, NSString *title) {
		objTitle = title;
		return nil;
	} forSlot:@"setTitle" argumentCount:2];

	[obj setTitle:@"test 2"];
	STAssertEqualObjects(obj.title, @"test 2", @"");
}
@end
