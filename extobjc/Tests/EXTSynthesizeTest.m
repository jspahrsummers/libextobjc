//
//  EXTSynthesizeTest.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-05-15.
//  Released into the public domain.
//

#import "EXTSynthesizeTest.h"

@interface SynthesisTestClass : NSObject {}
@property (nonatomic, copy) NSString *str;
@property (assign) char someChar;
@end

@implementation SynthesisTestClass
@synthesizeall;
@end

@implementation EXTSynthesizeTest

- (void)testSynthesizeAll {
	SynthesisTestClass *obj = [[SynthesisTestClass alloc] init];
	STAssertNotNil(obj, @"could not create instance of SynthesisTestClass");

	STAssertNil(obj.str, @"synthesized NSString property should be nil at initialization");
	STAssertEquals(obj.someChar, '\0', @"synthesized char property should be NUL at initialization");

	NSMutableString *mutStr = [[NSMutableString alloc] initWithString:@"foo"];
	obj.str = mutStr;

	STAssertEqualObjects(obj.str, mutStr, @"synthesized NSString property should have copied assigned string");
	STAssertFalse(obj.str == mutStr, @"synthesized NSString property should have copied assigned string");

	[mutStr appendString:@"bar"];
	STAssertFalse([obj.str isEqualToString:mutStr], @"synthesized NSString property should have copied assigned string");

	obj.str = nil;
	STAssertNil(obj.str, @"synthesized NSString property should be nil after being set as such");

	STAssertNoThrow([mutStr release], @"");
	STAssertNoThrow([obj release], @"exception thrown when releasing SynthesisTestClass object");
}

@end
