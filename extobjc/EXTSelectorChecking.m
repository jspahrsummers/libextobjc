//
//  EXTSelectorChecking.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 26.06.12.
//  Copyright (C) 2012 Justin Spahr-Summers.
//  Released under the MIT license.
//

#import "EXTSelectorChecking.h"

@implementation NSString (EXTCheckedSelectorAdditions)
- (SEL)ext_toSelector {
    return NSSelectorFromString(self);
}

@end
