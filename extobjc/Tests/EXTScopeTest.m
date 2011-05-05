//
//  EXTScopeTest.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-05-04.
//  Released into the public domain.
//

#import "EXTScopeTest.h"

@implementation EXTScopeTest

- (void)testOnExit {
	NSMutableString *str = [@"foo" mutableCopy];
	@onExit {
		[str release];
	};

	{
		@onExit {
			[str appendString:@"bar"];
		};
	}

	STAssertEqualObjects(str, @"foobar", @"'bar' should've been appended to 'foo' at the end of the previous scope");
}

@end
