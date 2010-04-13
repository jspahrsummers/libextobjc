/**
 * libextc scope testcase
 * ExtendedC
 *
 * by Justin Spahr-Summers
 * Copyright (C) 2010
 */

#include <assert.h>
#include <stdbool.h>
#include <stdlib.h>
#include "scope_test.h"

static
void scope_alloc (void);

void scope_test (void) {
    scope_alloc();
}

void scope_alloc (void) {
    void *ptr = NULL;
    bool cleaned_up = false;
    
    // destructor-like functionality!
    // similar to the scope() constructs in the D programming language
    
    scope(new) {
        ptr = malloc(1024);
        
        // frees the just-allocated memory *when this scope exits*
        scope(exit) {
            free(ptr);
            ptr = NULL;
            
            cleaned_up = true;
        }
        
        // 'ptr' has not been freed yet!
        assert(ptr != NULL);
        cleaned_up = false;
    }
    
    // 'ptr' has now been freed!
    assert(cleaned_up);
}
