/**
 * libextc memory testcase
 * ExtendedC
 *
 * by Justin Spahr-Summers
 * Copyright (C) 2010
 */

#include "exception.h"
#include "memory_test.h"

void memory_benchmark (void) {
    // don't allocate any significant amount right here
    // we're benchmarking how much overhead allocating with the memory module involves
    BENCHMARK(void *ptr = malloc(1); free(ptr));
    BENCHMARK(void *ptr = extc_malloc(1); extc_free(ptr));
    
    void *a = malloc(256);
    void *b = malloc(256);
    BENCHMARK_TIMES(DEFAULT_BENCHMARK_TIMES / 10, extc_memswap(a, b, 256));
    BENCHMARK_TIMES(DEFAULT_BENCHMARK_TIMES / 10, unsigned char c[256]; memcpy(c, a, 256); memcpy(a, b, 256); memcpy(b, c, 256));
    free(a);
    free(b);
    
    a = malloc(1024);
    b = malloc(1024);
    BENCHMARK_TIMES(DEFAULT_BENCHMARK_TIMES / 50, extc_memswap(a, b, 1024));
    BENCHMARK_TIMES(DEFAULT_BENCHMARK_TIMES / 50, unsigned char c[1024]; memcpy(c, a, 1024); memcpy(a, b, 1024); memcpy(b, c, 1024));
    free(a);
    free(b);
    
    a = malloc(65536);
    b = malloc(65536);
    BENCHMARK_TIMES(DEFAULT_BENCHMARK_TIMES / 1000, extc_memswap(a, b, 65536));
    BENCHMARK_TIMES(DEFAULT_BENCHMARK_TIMES / 1000, void *c = malloc(65536); memcpy(c, a, 65536); memcpy(a, b, 65536); memcpy(b, c, 65536); free(c));
    free(a);
    free(b);
}

void memory_test (void) {
    // test that allocation always returns NULL or an exception
    LOG_TEST("running successively bigger allocations until we fail");
    
    size_t allocSize = 2048;
    try {
        for (;;) {
            LOG_TEST("allocating %zu bytes", allocSize);
            void *ptr = extc_malloc(allocSize);
            assert(ptr != NULL);
            
            LOG_TEST("successful allocation, freeing");
            extc_free(ptr);
            
            if (allocSize == SIZE_MAX)
                // still didn't fail, just break out
                break;
            
            allocSize <<= 4;
            if (allocSize < 1024)
                // less than starting number, so we wrapped around
                // try SIZE_MAX instead
                allocSize = SIZE_MAX;
        }
    } catch_all (ex) {
        LOG_TEST("failed allocation");
    }

    // tests memory swapping code!
    
    char strA[] = "hello world";
    char strB[] = "foobar     ";
    
    LOG_TEST("swapping \"%s\" and \"%s\"", strA, strB);
    
    extc_memswap(strA, strB, 12);
    assert(strncmp(strA, "foobar", 6) == 0);
    assert(strncmp(strB, "hello world", 11) == 0);
    
    LOG_TEST("swapping the first six bytes of \"%s\" and \"%s\"", strA, strB);
    
    extc_memswap(strA, strB, 6);
    assert(strcmp(strA, "hello      ") == 0);
    assert(strcmp(strB, "foobarworld") == 0);
    
    LOG_TEST("now have \"%s\" and \"%s\"", strA, strB);
}
