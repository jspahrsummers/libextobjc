//
//  EXTSelectorCheckingTest.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 26.06.12.
//  Released into the public domain.
//

#import "EXTSelectorCheckingTest.h"

@implementation EXTSelectorCheckingTest

- (void)testCheckedSelectors {
    NSString *str = @"foobar";
    STAssertEquals(@checkselector(str, compare:, options:), @selector(compare:options:), @"");

    STAssertEquals(@checkselector([NSURL class], URLWithString:), @selector(URLWithString:), @"");
}

@end
