//
//  EXTConcreteProtocolTest.h
//  extobjc
//
//  Created by Justin Spahr-Summers on 2010-11-09.
//  Copyright (C) 2012 Justin Spahr-Summers.
//  Released under the MIT license.
//

#import <SenTestingKit/SenTestingKit.h>
#import <Foundation/Foundation.h>
#import "EXTConcreteProtocol.h"

@protocol MyProtocol <NSObject>
@concrete
+ (NSUInteger)meaningfulNumber;
- (NSString *)getSomeString;
@end

@protocol SubProtocol <MyProtocol>
@concrete
- (void)additionalMethod;
@end

@interface EXTConcreteProtocolTest : SenTestCase {

}

- (void)testImplementations;
- (void)testSimpleInheritance;
- (void)testClassInheritanceWithProtocolInheritance;
- (void)testInheritanceChain;

@end
