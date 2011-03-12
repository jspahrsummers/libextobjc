//
//  EXTPrototypeTest.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-03-12.
//  Released into the public domain.
//

#import "EXTPrototypeTest.h"

@slot(title)

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
	STAssertEquals([obj valueForSlot:@"title"], method, @"");

	NSString *title = obj.title;
	STAssertEquals(title, @"test title", @"");
}

- (void)testPrototypeCopying {
	EXTPrototype *orig = [EXTPrototype prototype];
	orig.title = blockMethod(id self){ return @"test"; };

	STAssertEquals(orig.title, @"test", @"");

	NSLog(@"%s: %lu", __FILE__, (unsigned long)__LINE__);

	EXTPrototype *copy = [orig copy];
	copy.title = blockMethod(id self){
		return @"test_copy";
		//return [orig.title stringByAppendingString:@"_copy"];
	};

	NSLog(@"%s: %lu", __FILE__, (unsigned long)__LINE__);

	STAssertEquals(orig.title, @"test", @"");

	NSLog(@"%s: %lu", __FILE__, (unsigned long)__LINE__);

	STAssertEquals(copy.title, @"test_copy", @"");

	NSLog(@"%s: %lu", __FILE__, (unsigned long)__LINE__);
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
	} forSlot:@"setTitle:" argumentCount:2];

	[obj setTitle:@"test 2"];
	STAssertEquals(obj.title, @"test 2", @"");
}
@end
