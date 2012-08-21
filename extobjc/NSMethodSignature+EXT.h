//
//  NSMethodSignature+EXT.h
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-03-11.
//  Copyright (C) 2012 Justin Spahr-Summers.
//  Released under the MIT license.
//

#import <Foundation/Foundation.h>

@interface NSMethodSignature (EXTExtensions)
/**
 * Creates and returns a new method signature based off the receiver, but with
 * an additional argument of the given type at \a index. If \a index is greater
 * than the current number of arguments, the behavior is undefined.
 */
- (NSMethodSignature *)methodSignatureByInsertingType:(const char *)type atArgumentIndex:(NSUInteger)index;

/**
 * Returns the Objective-C type encoding for this method signature, which
 * includes the return type and all arguments. The resultant string matches the
 * format of \c method_getTypeEncoding() and is suitable for passing to \c
 * class_addMethod() and similar facilities.
 *
 * @note The returned string is autoreleased.
 */
- (const char *)typeEncoding;
@end
