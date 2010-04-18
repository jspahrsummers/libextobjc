/**
 * libextc memory testcase
 * ExtendedC
 *
 * by Justin Spahr-Summers
 * Copyright (C) 2010
 */

#include "exception.h"
#include "memory_test.h"

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
