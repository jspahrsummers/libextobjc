/**
 * libextc testcase runner
 * ExtendedC
 *
 * by Justin Spahr-Summers
 * Copyright (C) 2010
 */

#include "exception_test.h"
#include "vector_test.h"

int main (void) {
    vector_test();
    exception_test();
    return 0;
}
