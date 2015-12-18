//
//  NSObject+EXT.h
//  extobjc
//
//  Created by Anton Bukov on 18.12.15.
//  Copyright (C) 2015 Anton Bukov (@k06a)
//  Released under the MIT license.
//

#import <Foundation/Foundation.h>

@interface NSObject (EXTExtensions)
/**
 * Returns object itself or \c nil if object is \c NSNull or \c EXTNil
 */
- (instancetype)selfOrNil;
@end
