/**
 * libextc refcounted testcase
 * ExtendedC
 *
 * by Justin Spahr-Summers
 * Copyright (C) 2010
 */

#include "refcounted_test.h"

void refcounted_test (void) {
    // allocates a reference-counted string
    refcounted(const char *) *str = refcounted_new(const char *);
    
    // copy the refcounted pointer because it'll get set to NULL later
    refcounted(const char *) *strRef = str;
    
    str->value = "hello world";
    LOG_TEST("allocated refcounted object %p (with backup pointer %p) and set value to \"%s\"", (void *)str, (void *)strRef, str->value);
    
    // returns the value after incrementing the reference count
    LOG_TEST("retaining %p", (void *)str);
    
    const char *result = retain(str);
    assert(strcmp(result, "hello world") == 0);
    assert(str->refcount_ == 2);
    
    // decrements the reference count and sets 'str' to NULL
    LOG_TEST("releasing %p and setting variable to NULL", (void *)str);
    
    release(str);
    assert(str == NULL);
    assert(strRef->refcount_ == 1);
    
    // decrements the reference count (now at 0) and frees the object
    LOG_TEST("releasing other variable %p and freeing", (void *)strRef);
    
    release(strRef);
    assert(strRef == NULL);
}
