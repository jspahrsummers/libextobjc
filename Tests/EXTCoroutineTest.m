//
//  EXTCoroutineTest.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-05-22.
//  Copyright (C) 2012 Justin Spahr-Summers.
//  Released under the MIT license.
//

#import "EXTCoroutineTest.h"


@implementation EXTCoroutineTest

- (void)testYield {
    __block int i;

    int (^myCoroutine)(void) = coroutine(void)({
        for (i = 0;i < 3;++i) {
            yield i;
        }
    });

    STAssertEquals(myCoroutine(), 0, @"expected first coroutine call to yield 0");
    STAssertEquals(myCoroutine(), 1, @"expected second coroutine call to yield 1");
    STAssertEquals(myCoroutine(), 2, @"expected third coroutine call to yield 2");
    STAssertEquals(myCoroutine(), 0, @"expected restarted coroutine call to yield 0");
    STAssertEquals(myCoroutine(), 1, @"expected second coroutine call to yield 1");

    myCoroutine = coroutine(void)({
        yield 5;
        yield 18;
    });

    STAssertEquals(myCoroutine(), 5, @"expected first coroutine call to yield 5");
    STAssertEquals(myCoroutine(), 18, @"expected second coroutine call to yield 18");
    STAssertEquals(myCoroutine(), 5, @"expected restarted coroutine call to yield 5");
}

@end
