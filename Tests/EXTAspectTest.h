//
//  EXTAspectTest.h
//  extobjc
//
//  Created by Justin Spahr-Summers on 25.11.11.
//  Copyright (C) 2012 Justin Spahr-Summers.
//  Released under the MIT license.
//

#import <SenTestingKit/SenTestingKit.h>
#import "EXTAspect.h"

@interface EXTAspectTest : SenTestCase
@end

@aspect(TestAspect);
@aspect(OtherTestAspect);
