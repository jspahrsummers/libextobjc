/**
 * libextc testcase runner
 * ExtendedC
 *
 * by Justin Spahr-Summers
 * Copyright (C) 2010
 */

#include "algorithm_test.h"
#include "contracts_test.h"
#include "enum_test.h"
#include "exception_test.h"
#include "memory_test.h"
#include "refcounted_test.h"
#include "scope_test.h"
#include "test.h"
#include "vector_test.h"

int main (void) {
    putc('\n', stdout);

    // a couple modules depend on exception handling functionality
    // so run the tests there before any dependent ones
    TEST_MODULE(exception);
    
    TEST_MODULE(algorithm);
    TEST_MODULE(contracts);
    TEST_MODULE(enum);
    TEST_MODULE(memory);
    TEST_MODULE(refcounted);
    TEST_MODULE(scope);
    TEST_MODULE(vector);
    
    BENCHMARK_MODULE(algorithm);
    BENCHMARK_MODULE(enum);
    BENCHMARK_MODULE(exception);
    BENCHMARK_MODULE(memory);
    BENCHMARK_MODULE(refcounted);
    BENCHMARK_MODULE(scope);
    BENCHMARK_MODULE(vector);
    return 0;
}
