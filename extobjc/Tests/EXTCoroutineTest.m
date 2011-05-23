//
//  EXTCoroutineTest.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-05-22.
//  Released into the public domain.
//

#import "EXTCoroutineTest.h"


@implementation EXTCoroutineTest

- (void)testYield {
	__block int i;

	int (^myCoroutine)(void) =
		coroutine(void)({
			for (i = 0;i < 3;++i) {
				yield i;
			}
		});

	STAssertEquals(myCoroutine(), 0, @"expected first coroutine call to yield 0");
	STAssertEquals(myCoroutine(), 1, @"expected second coroutine call to yield 1");
	STAssertEquals(myCoroutine(), 2, @"expected third coroutine call to yield 2");
	STAssertEquals(myCoroutine(), 0, @"expected restarted coroutine call to yield 0");
	STAssertEquals(myCoroutine(), 1, @"expected second coroutine call to yield 1");
}

@end
