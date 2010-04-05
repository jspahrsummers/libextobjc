/**
 * libextc testcase runner
 * ExtendedC
 *
 * by Justin Spahr-Summers
 * Copyright (C) 2010
 */

#include "exceptions_test.h"
#include "vector_test.h"

int main (void) {
    vector_test();
    exceptions_test();
    return 0;
}
