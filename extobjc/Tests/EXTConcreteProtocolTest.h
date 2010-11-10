//
//  EXTConcreteProtocolTest.h
//  extobjc
//
//  Created by Justin Spahr-Summers on 2010-11-09.
//  Copyright 2010 Übermind, Inc. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "EXTConcreteProtocol.h"

@protocol MyProtocol <NSObject>
@optional
- (void)doSomethingInteresting;
@end

@interface EXTConcreteProtocolTest : SenTestCase {

}

- (void)testImplementations;

@end
