//
//  NSObject+EXT.m
//  extobjc
//
//  Created by Anton Bukov on 18.12.15.
//  Copyright (C) 2015 Anton Bukov (@k06a)
//  Released under the MIT license.
//

#import "EXTNil.h"
#import "NSObject+EXT.h"

@implementation NSObject (EXTExtensions)
- (instancetype)selfOrNil {
    if (self != [NSNull null] && self != [EXTNil null]) {
        return self;
    }
    return nil;
}
@end
