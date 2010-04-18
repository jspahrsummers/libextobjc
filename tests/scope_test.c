/**
 * libextc scope testcase
 * ExtendedC
 *
 * by Justin Spahr-Summers
 * Copyright (C) 2010
 */

#include "scope_test.h"

static
void scope_alloc (void);

void scope_test (void) {
    scope_alloc();
}

void scope_alloc (void) {
    LOG_TEST("using scope() to automatically deallocate memory");

    void *ptr = NULL;
    bool cleaned_up = false;
    
    // destructor-like functionality!
    // similar to the scope() constructs in the D programming language
    
    scope(new) {
        ptr = malloc(256);
        assert(ptr != NULL);
        LOG_TEST("allocated pointer %p", (void *)ptr);
        
        // frees the just-allocated memory *when this scope exits*
        scope(exit) {
            LOG_TEST("inside scope cleanup, freeing pointer %p", (void *)ptr);
            free(ptr);
            ptr = NULL;
        }
        
        scope(exit) {
            LOG_TEST("inside second scope cleanup");
            cleaned_up = true;
            
            // previous cleanup block should've been executed already
            assert(ptr == NULL);
        }
        
        // 'ptr' has not been freed yet!
        assert(ptr != NULL);
        cleaned_up = false;
        
        LOG_TEST("about to leave scope");
    }
    
    // 'ptr' has now been freed!
    assert(cleaned_up);
    assert(ptr == NULL);
    LOG_TEST("scope has been cleaned up");
}
