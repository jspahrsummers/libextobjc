//
//  EXTMaybeTest.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 21.01.12.
//  Copyright (C) 2012 Justin Spahr-Summers.
//  Released under the MIT license.
//

#import "EXTMaybeTest.h"
#import "EXTMaybe.h"
#import "EXTNil.h"

@interface EXTMaybeTest ()
@property (nonatomic, copy, readonly) NSString *errorDomain;
@property (nonatomic, assign, readonly) NSInteger errorCode;
@property (nonatomic, copy, readonly) NSString *errorDescription;
@property (nonatomic, copy, readonly) NSError *error;
@end

@implementation EXTMaybeTest

- (NSString *)errorDomain {
    return @"SomeErrorDomain";
}

- (NSInteger)errorCode {
    return 15;
}

- (NSString *)errorDescription {
    return @"This is an error description.";
}

- (NSError *)error {
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey: self.errorDescription};

    NSError *error = [NSError errorWithDomain:self.errorDomain code:self.errorCode userInfo:userInfo];
	
    XCTAssertNotNil(error, @"");

    return error;
}

- (void)testErrorMaybe {
    NSError *error = self.error;
    id maybe = [EXTMaybe maybeWithError:error];
    XCTAssertNotNil(maybe, @"");

    XCTAssertEqualObjects(maybe, error, @"");
	
    XCTAssertTrue([maybe isKindOfClass:[NSError class]], @"");
    XCTAssertTrue([maybe isMemberOfClass:[NSError class]], @"");
    XCTAssertTrue([maybe isProxy], @"");

    // test an NSString method
    XCTAssertEqual([maybe length], (NSUInteger)0, @"");

    id obj = [EXTMaybe validObjectWithMaybe:maybe orElse:^(NSError *localError){
        XCTAssertEqualObjects(error, localError, @"");

        return @YES;
    }];

    XCTAssertEqualObjects(obj, [NSNumber numberWithBool:YES], @"");
}

- (void)testValidObjectWithMaybeNil {
    id obj = [EXTMaybe validObjectWithMaybe:nil orElse:^(NSError *localError){
        XCTAssertNil(localError, @"");

        return @YES;
    }];

    XCTAssertEqualObjects(obj, [NSNumber numberWithBool:YES], @"");
}

- (void)testValidObjectWithMaybeEXTNil {
    id obj = [EXTMaybe validObjectWithMaybe:[EXTNil null] orElse:^(NSError *localError){
        XCTAssertNil(localError, @"");

        return @YES;
    }];

    XCTAssertEqualObjects(obj, [NSNumber numberWithBool:YES], @"");
}

- (void)testValidObjectWithMaybeNSNull {
    id obj = [EXTMaybe validObjectWithMaybe:[NSNull null] orElse:^(NSError *localError){
        XCTAssertNil(localError, @"");

        return @YES;
    }];

    XCTAssertEqualObjects(obj, [NSNumber numberWithBool:YES], @"");
}

- (void)testValidObjectWithMaybeEXTNilAndNilBlock {
    id obj = [EXTMaybe validObjectWithMaybe:[EXTNil null] orElse:nil];
    XCTAssertNil(obj, @"");
}

- (void)testValidObject {
    NSString *str = @"foobar";
    id obj = [EXTMaybe validObjectWithMaybe:str orElse:nil];

    XCTAssertEqualObjects(obj, str, @"");
}

@end
