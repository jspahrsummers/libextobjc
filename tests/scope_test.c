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
    
    scope(new) {
        ptr = malloc(1024);
        scope(exit) {
            free(ptr);
            ptr = NULL;
            
            cleaned_up = true;
        }
        
        assert(ptr != NULL);
        cleaned_up = false;
    }
    
    assert(cleaned_up);
}
