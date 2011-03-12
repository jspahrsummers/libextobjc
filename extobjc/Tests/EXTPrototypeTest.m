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

	NSString *title = obj.title;
	STAssertEquals(title, @"test title", @"");
}

- (void)testAddingSetter {
	EXTPrototype *obj = [EXTPrototype prototype];

	__block NSString *objTitle = nil;

	obj.title = blockMethod(id self){ return objTitle; };

	NSString *title = obj.title;
	STAssertNil(title, @"");

	[obj setSetTitle:blockMethod(id self, NSString *title) {
		objTitle = title;
		return nil;
	} argumentCount:2];

	[obj setTitle:@"test 2"];
	STAssertEquals(obj.title, @"test 2", @"");
}
@end
