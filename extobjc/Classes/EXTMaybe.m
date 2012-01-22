//
//  EXTMaybe.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 21.01.12.
//  Released into the public domain.
//

#import "EXTMaybe.h"

@implementation EXTMaybe

#pragma mark Lifecycle

+ (id)maybeWithError:(NSError *)error; {
    return nil;
}

#pragma mark Unwrapping

+ (id)validObjectWithMaybe:(id)maybe orElse:(id (^)(NSError *))block; {
    return nil;
}

@end
