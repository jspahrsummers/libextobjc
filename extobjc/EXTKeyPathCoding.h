//
//  EXTKeyPathCoding.h
//  extobjc
//
//  Created by Justin Spahr-Summers on 19.06.12.
//  Copyright (C) 2012 Justin Spahr-Summers.
//  Released under the MIT license.
//

#import <Foundation/Foundation.h>

/**
 * \@keypath allows compile-time verification of key paths. Given a real object
 * receiver and key path (e.g., \c str.lowercaseString.UTF8String or \c
 * NSObject.class.version), the macro returns an \c NSString containing all but
 * the first path component (e.g., @"lowercaseString.UTF8String",
 * @"class.version").
 *
 * In addition to simply creating a key path, this macro ensures that the key
 * path is valid at compile-time (causing a syntax error if not), and supports
 * refactoring, such that changing the name of the property will also update any
 * uses of \@keypath.
 *
 * \a PATH must contain at least two components (a receiver and a key).
 */
#define keypath(PATH) \
    (((void)(NO && ((void)PATH, NO)), strchr(# PATH, '.') + 1))
