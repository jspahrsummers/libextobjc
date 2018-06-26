//
//  EXTKeypathWeakWarningTest.m
//  extobjc
//
//  Created by Javier Soto on 6/23/14.
//
//

#import "EXTKeypathWeakWarningTest.h"

#pragma clang diagnostic push
#pragma clang diagnostic error "-Warc-repeated-use-of-weak"

@interface EXTClassWithWeakProperty : NSObject

@property (nonatomic, weak) NSString *property;

@end

@implementation EXTClassWithWeakProperty

@end

@implementation EXTKeypathWeakWarningTest

- (void)testWarningIsNotEmitted {
    __unused NSString * _Nonnull keypath = @keypath(EXTClassWithWeakProperty.new, property);
    __unused NSString * _Nonnull keypath2 = @keypath(EXTClassWithWeakProperty.new, property);
}

@end

#pragma clang diagnostic pop
