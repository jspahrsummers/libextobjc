//
//  EXTSwizzleTest.m
//  libextobjc
//
//  Created by Justin Spahr-Summers on 2010-08-15.
//  Released into the public domain.
//

#import "EXTSwizzleTest.h"

/* Test category for macro manipulation */
@interface NSURLRequest (SwizzleTestCategory)
- (id)replacementSelf;

+ (Class)replacementClass;
@end

@implementation NSURLRequest (SwizzleTestCategory)
- (void)replacementDealloc {
	[self oldDealloc];
}

- (id)replacementSelf {
	return [NSString string];
}

+ (Class)replacementClass {
	return [NSString class];
}
@end
/* End test category for macro manipulation */

@implementation EXTSwizzleTests
- (void)testInstanceMethodSwap {
	NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://www.google.com"]];
	STAssertNotNil(request, @"could not initialize NSURLRequest test object");
	
	STAssertTrue([request respondsToSelector:@selector(replacementSelf)], @"NSURLRequest category did not load at test case startup");
	STAssertTrueNoThrow([[request replacementSelf] isKindOfClass:[NSString class]], @"expected -replacementSelf of NSURLRequest to return a string");
	STAssertEquals(request, [request self], @"expected -self of NSURLRequest object to match itself");
	
	EXT_SWIZZLE_INSTANCE_METHODS(
		NSURLRequest,
		self,
		replacementSelf,
		oldSelf
	);
	
	STAssertTrueNoThrow([[request self] isKindOfClass:[NSString class]], @"expected -self of NSURLRequest object to return a string after swapping implementation");
	STAssertTrue([request respondsToSelector:@selector(oldSelf)], @"expected NSURLRequest to respond to -oldSelf after renaming -self");
	STAssertEquals([request oldSelf], request, @"expected -oldSelf of NSURLRequest object to match itself after swapping implementation");
	
	STAssertNoThrow([request release], @"releasing a valid NSURLRequest after swizzling methods should not throw an exception");
	request = nil;
	
	// ensure that superclass implementations are intact
	NSObject *obj = [[NSObject alloc] init];
	STAssertNotNil(obj, @"could not initialize NSObject test object");
	
	STAssertFalse([obj respondsToSelector:@selector(replacementSelf)], @"NSURLRequest category is available on NSObject, when it shouldn't be");
	STAssertFalse([obj respondsToSelector:@selector(oldSelf)], @"expected NSObject not to respond to -oldSelf even after renaming subclass method");
	STAssertEquals(obj, [obj self], @"expected -self of NSObject object to match itself even after renaming subclass method");
	
	STAssertNoThrow([obj release], @"releasing a valid NSObject after swizzling on subclass should not throw an exception");
	obj = nil;
}

- (void)testClassMethodSwap {
	STAssertEqualObjects([NSURLRequest class], NSClassFromString(@"NSURLRequest"), @"expected [NSURLRequest class] to equal NSURLRequest");

	STAssertTrue([NSURLRequest respondsToSelector:@selector(replacementClass)], @"NSURLRequest category did not load at test case startup");
	STAssertEqualObjects([NSURLRequest replacementClass], [NSString class], @"expected [NSURLRequest replacementClass] to equal [NSString class]");
	
	EXT_SWIZZLE_CLASS_METHODS(
		NSURLRequest,
		class,
		replacementClass,
		oldClass
	);
	
	STAssertEqualObjects([NSURLRequest class], [NSString class], @"expected [NSURLRequest class] to equal [NSString class] after swapping out implementation");
	STAssertTrue([NSURLRequest respondsToSelector:@selector(oldClass)], @"expected NSURLRequest to respond to +oldClass after renaming +class");
	STAssertTrueNoThrow([[NSURLRequest oldClass] isEqual:NSClassFromString(@"NSURLRequest")], @"expected [NSURLRequest oldClass] to be a valid method that equals NSURLRequest");
	
	// ensure that superclass implemenations are intact
	STAssertEqualObjects([NSObject class], NSClassFromString(@"NSObject"), @"expected [NSObject class] to equal NSObject");
	STAssertFalse([NSObject respondsToSelector:@selector(replacementClass)], @"NSURLRequest category is available on NSObject, when it shouldn't be");
	STAssertFalse([NSObject respondsToSelector:@selector(oldClass)], @"expected NSObject not to respond to +oldClass after renaming +class in subclass");
}

@end
