//
//  EXTRuntimeTestProtocol.h
//  extobjc
//
//  Created by Clay Bridges on 8/5/13.
//
//

#import <Foundation/Foundation.h>

@protocol EXTRuntimeTestProtocol <NSObject>

@optional
+ (void)optionalClassMethod;
- (void)optionalInstanceMethod;

@end
