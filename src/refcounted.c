/**
 * refcounted(T) template
 * ExtendedC
 *
 * by Justin Spahr-Summers
 * Copyright (C) 2010
 */

#include <assert.h>
#include <string.h>
#include "memory.h"
#include "refcounted.h"

// used for accessing the fields in the structure
typedef refcounted(unsigned char) refcounted_t;

refcounted_ptr refcounted_new_ (size_t structSize) {
    refcounted_t *ptr = extc_malloc(structSize);
    ptr->refcount_ = 1;
    ptr->structSize_ = structSize;
    return ptr;
}

void refcounted_release_ (refcounted_ptr ptr) {
    refcounted_t *ref = ptr;
    assert(ref != NULL);
    assert(ref->refcount_ > 0);
    
    if (--ref->refcount_ == 0) {
        unsigned char *valueData = ptr;
        
        size_t prefaceSize = sizeof(refcount_t) + sizeof(size_t);
        assert(prefaceSize < ref->structSize_);
        
        // zero out the 'value' field to help catch errors
        memset(valueData + prefaceSize, 0, ref->structSize_ - prefaceSize);
    }
    
    extc_free(ref);
}
