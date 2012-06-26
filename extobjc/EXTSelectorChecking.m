//
//  EXTSelectorChecking.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 26.06.12.
//  Released into the public domain.
//

#import "EXTSelectorChecking.h"

@implementation NSString (EXTCheckedSelectorAdditions)
- (SEL)ext_toSelector {
    return NSSelectorFromString(self);
}

@end
