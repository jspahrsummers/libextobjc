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

@slot(string)
@slot(appendString)
@slot(replaceOccurrencesOfString)

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
	orig.title = blockMethod(id self){ return @"test"; };

	STAssertEqualObjects(orig.title, @"test", @"");

	EXTPrototype *copy = [orig copy];
	STAssertNotNil(copy, @"copy of proto-object should not be nil");

	copy.title = blockMethod(id self){
		return [orig.title stringByAppendingString:@"_copy"];
	};

	STAssertEqualObjects(orig.title, @"test", @"");
	STAssertEqualObjects(copy.title, @"test_copy", @"");
}

- (void)testPrototypeLookup {
	EXTPrototype *superObj = [EXTPrototype prototype];
	superObj.title = blockMethod(id self){ return @"test"; };

	STAssertEqualObjects(superObj.title, @"test", @"");

	EXTPrototype *subObj = [EXTPrototype prototype];
	subObj.parent = superObj;

	STAssertEqualObjects(superObj.title, @"test", @"");
	STAssertEqualObjects(subObj.parent, superObj, @"");
	STAssertEqualObjects(subObj.title, superObj.title, @"");
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

- (void)testPropertySynthesis {
	EXTPrototype *obj = [EXTPrototype prototype];

	// this creates ATOMIC accessors
	[obj synthesizeSlot:@"title"];

	STAssertNil(obj.title, @"");

	obj.title = @"test";
	STAssertEqualObjects(obj.title, @"test", @"");

	[obj setTitle:@"test 2"];
	STAssertEqualObjects(obj.title, @"test 2", @"");
}

- (void)testArgumentSlots {
	EXTPrototype *obj = [EXTPrototype prototype];
	obj.string = @"";

	STAssertEqualObjects(obj.string, @"", @"");

	[obj setBlock:blockMethod(EXTPrototype *self, NSString *append){
		self.string = [self.string stringByAppendingString:append];
	} forSlot:@"appendString" argumentCount:2];

	[obj setBlock:blockMethod(EXTPrototype *self, NSString *search, NSString *replace){
		self.string = [self.string stringByReplacingOccurrencesOfString:search withString:replace];
	} forSlot:@"replaceOccurrencesOfString" argumentCount:3];

	STAssertEqualObjects(obj.string, @"", @"");

	[obj appendString:@"foobar"];
	STAssertEqualObjects(obj.string, @"foobar", @"");

	[obj replaceOccurrencesOfString:@"foo" withObject:@"bar"];
	STAssertEqualObjects(obj.string, @"barbar", @"");

	// slot replaceOccurrencesOfString should be invokable with any name for the
	// additional arguments
	[obj performSelector:@selector(replaceOccurrencesOfString:withString:) withObject:@"bar" withObject:@"foo"];
	STAssertEqualObjects(obj.string, @"foofoo", @"");

	[obj performSelector:@selector(replaceOccurrencesOfString:somethingElse:) withObject:@"foo" withObject:@"beef"];
	STAssertEqualObjects(obj.string, @"beefbeef", @"");
}
@end
