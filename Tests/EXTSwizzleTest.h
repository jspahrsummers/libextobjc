//
//  EXTSwizzleTest.h
//  extobjc
//
//  Created by Justin Spahr-Summers on 2010-08-15.
//  Copyright (C) 2012 Justin Spahr-Summers.
//  Released under the MIT license.
//

#import <XCTest/XCTest.h>
#import <Foundation/Foundation.h>
#import "EXTSwizzle.h"

@interface EXTSwizzleTests : XCTestCase {

}

- (void)testInstanceMethodSwap;
- (void)testClassMethodSwap;

@end
