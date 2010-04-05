/**
 * libextc refcounted testcase
 * ExtendedC
 *
 * by Justin Spahr-Summers
 * Copyright (C) 2010
 */

#include <assert.h>
#include <string.h>
#include "refcounted_test.h"

void refcounted_test (void) {
    refcounted(const char *) *str = refcounted_new(const char *);
    
    str->value = "hello world";
    
    const char *result = retain(str);
    assert(strcmp(result, "hello world") == 0);
    assert(str->refcount_ == 2);
    
    release(str);
    assert(str->refcount_ == 1);
    
    release(str);
    assert(str == NULL);
}
