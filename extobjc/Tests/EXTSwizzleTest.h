//
//  EXTSwizzleTest.h
//  libextobjc
//
//  Created by Justin Spahr-Summers on 2010-08-15.
//  Released into the public domain.
//

#import <SenTestingKit/SenTestingKit.h>
#import "EXTSwizzle.h"

@interface EXTSwizzleTests : SenTestCase {

}

- (void)testInstanceMethodSwap;
- (void)testClassMethodSwap;

@end
