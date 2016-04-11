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

    XCTAssertEqual(myCoroutine(), 0, @"expected first coroutine call to yield 0");
    XCTAssertEqual(myCoroutine(), 1, @"expected second coroutine call to yield 1");
    XCTAssertEqual(myCoroutine(), 2, @"expected third coroutine call to yield 2");
    XCTAssertEqual(myCoroutine(), 0, @"expected restarted coroutine call to yield 0");
    XCTAssertEqual(myCoroutine(), 1, @"expected second coroutine call to yield 1");

    myCoroutine = coroutine(void)({
        yield 5;
        yield 18;
    });

    XCTAssertEqual(myCoroutine(), 5, @"expected first coroutine call to yield 5");
    XCTAssertEqual(myCoroutine(), 18, @"expected second coroutine call to yield 18");
    XCTAssertEqual(myCoroutine(), 5, @"expected restarted coroutine call to yield 5");
}

@end
