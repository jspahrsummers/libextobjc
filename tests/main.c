/**
 * libextc testcase runner
 * ExtendedC
 *
 * by Justin Spahr-Summers
 * Copyright (C) 2010
 */

#include <stdio.h>
#include "algorithm_test.h"
#include "enum_test.h"
#include "exception_test.h"
#include "refcounted_test.h"
#include "scope_test.h"
#include "vector_test.h"

#define test(NAME) \
    (NAME ## _test(), printf("*** %s module passed all tests!\n", # NAME))

int main (void) {
    test(algorithm);
    test(enum);
    test(exception);
    test(refcounted);
    test(scope);
    test(vector);
    return 0;
}
