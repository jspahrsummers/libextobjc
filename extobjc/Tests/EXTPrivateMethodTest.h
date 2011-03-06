//
//  EXTPrivateMethodTest.h
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-03-02.
//  Released into the public domain.
//

#import <SenTestingKit/SenTestingKit.h>
#import "extobjc.h"

@protocol TestProtocol <NSObject>
@required
- (void)doStuff;
@end

@interface EXTPrivateMethodTest : SenTestCase {
@private
    
}

@end
