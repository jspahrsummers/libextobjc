/**
 * libextc memory testcase
 * ExtendedC
 *
 * by Justin Spahr-Summers
 * Copyright (C) 2010
 */

#include <assert.h>
#include <string.h>
#include "memory_test.h"

void memory_test (void) {
    char strA[] = "hello world";
    char strB[] = "foobar     ";
    
    extc_memswap(strA, strB, 12);
    assert(strncmp(strA, "foobar", 6) == 0);
    assert(strncmp(strB, "hello world", 11) == 0);
    
    extc_memswap(strA, strB, 6);
    assert(strcmp(strA, "hello      ") == 0);
    assert(strcmp(strB, "foobarworld") == 0);
}
