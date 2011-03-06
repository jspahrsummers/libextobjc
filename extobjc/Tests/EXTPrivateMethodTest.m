//
//  EXTPrivateMethodTest.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-03-02.
//  Released into the public domain.
//

#import "EXTPrivateMethodTest.h"

@interface PrivateTestClass : NSURLRequest {
}

- (int)stuff;

@end

@protocol TestProtocol;
@protocol FakeProtocol <TestProtocol>
@end

@interface NSURLRequest (Something) <FakeProtocol>
@end

@protocol TestProtocol
@end

@implementation PrivateTestClass (Something)
- (void)something {}
@end

@private (PrivateTestClass)
- (int)privateValue;
@endprivate

@implementation PrivateTestClass
+ (void)load {
	NSLog(@"%s", __func__);
}
	
+ (void)initialize {
	NSLog(@"%s", __func__);
}

- (int)stuff {
  	return [privateSelf privateValue];
}

- (int)privateValue {
	return 42;
}
@end

@implementation EXTPrivateMethodTest
- (void)testPrivateMethods {
	PrivateTestClass *obj = [[PrivateTestClass alloc] init];

	STAssertNotNil(obj, @"could not allocate instance of class with private methods");
	STAssertEquals([obj stuff], 42, @"expected -[PrivateTestClass stuff] to return 42");
	STAssertNoThrow([obj release], @"could not deallocate instance of class with private methods");
}
@end
