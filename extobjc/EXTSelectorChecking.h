//
//  EXTSelectorChecking.h
//  extobjc
//
//  Created by Justin Spahr-Summers on 26.06.12.
//  Copyright (C) 2012 Justin Spahr-Summers.
//  Released under the MIT license.
//

#import <Foundation/Foundation.h>
#import "metamacros.h"

/**
 * \@checkselector verifies at compile-time that a selector can be invoked
 * against the given TARGET. The checked selector is then returned as a SEL.
 *
 * The variadic arguments should be pieces of the selector, each ending with
 * ':'. For example:
 *
 * @code

[myButton addTarget:self action:@checkselector(self, buttonAction:) forControlEvents:UIControlEventTouchUpInside];
[otherButton addTarget:self action:@checkselector(self, buttonAction:, withEvent:) forControlEvents:UIControlEventTouchUpInside];

 * @endcode
 *
 * For zero-argument selectors, use \@checkselector0 instead.
 *
 * @bug This macro currently does not work with selectors with variadic
 * arguments.
 *
 * @bug This macro will not work if the method on TARGET designated by the
 * selector must accept a struct or union argument.
 */
#define checkselector(TARGET, ...) \
    (((void)(NO && ((void)[TARGET metamacro_foreach(ext_checkselector_message_iter,, __VA_ARGS__)], NO)), \
        metamacro_foreach(ext_checkselector_selector_iter,, __VA_ARGS__))).ext_toSelector

#define checkselector0(TARGET, SELECTOR) \
    (((void)(NO && ((void)[TARGET SELECTOR], NO)), \
        # SELECTOR)).ext_toSelector

/*** implementation details follow ***/
#define ext_checkselector_message_iter(INDEX, SELPART) \
    SELPART (0)

#define ext_checkselector_selector_iter(INDEX, SELPART) \
    # SELPART

@interface NSString (EXTCheckedSelectorAdditions)
- (SEL)ext_toSelector;
@end
