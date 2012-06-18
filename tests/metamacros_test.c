/**
 * libextc metamacros testcase
 * ExtendedC
 *
 * by Justin Spahr-Summers
 *
 * Released 18. Jun 2012 into the public domain.
 */

#include "metamacros.h"
#include "metamacros_test.h"

void metamacros_test (void) {
    assert(metamacro_argcount(a) == 1);
    assert(metamacro_argcount(a, b) == 2);
    assert(metamacro_argcount(a, b, c) == 3);
    assert(metamacro_argcount(a, b, c, d) == 4);
    assert(metamacro_argcount(a, b, c, d, e) == 5);
    assert(metamacro_argcount(a, b, c, d, e, f) == 6);
    assert(metamacro_argcount(a, b, c, d, e, f, g) == 7);
    assert(metamacro_argcount(a, b, c, d, e, f, g, h) == 8);
    assert(metamacro_argcount(a, b, c, d, e, f, g, h, i) == 9);
}
