//
//  EXTSwizzleTests.h
//  UberFoundation
//
//  Created by Justin Spahr-Summers on 2010-08-15.
//  Copyright 2010 Übermind, Inc. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import <UberFoundation/EXTSwizzle.h>

@interface EXTSwizzleTests : SenTestCase {

}

- (void)testMacroStringify;
- (void)testMacroConcatenate;

- (void)testInstanceMethodSwap;
- (void)testClassMethodSwap;

@end
