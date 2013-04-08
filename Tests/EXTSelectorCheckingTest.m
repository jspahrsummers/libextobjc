//
//  EXTSelectorCheckingTest.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 26.06.12.
//  Copyright (C) 2012 Justin Spahr-Summers.
//  Released under the MIT license.
//

#import "EXTSelectorCheckingTest.h"

@implementation EXTSelectorCheckingTest

- (void)testCheckedSelectors {
    NSString *str = @"foobar";
    STAssertEquals(@checkselector(str, compare:, options:), @selector(compare:options:), @"");

    STAssertEquals(@checkselector([NSURL class], URLWithString:), @selector(URLWithString:), @"");
}

- (void)testCheckSelectorsWithZeroArguments {
    NSString *str = @"foobar";
    STAssertEquals(@checkselector0(str, intValue), @selector(intValue), @"");
    STAssertEquals(@checkselector0([NSURL class], class), @selector(class), @"");
}

@end
