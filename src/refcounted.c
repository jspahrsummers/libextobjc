/**
 * refcounted(T) template
 * ExtendedC
 *
 * by Justin Spahr-Summers
 * Copyright (C) 2010
 */

#include "memory.h"
#include "refcounted.h"

// used for accessing the fields in the structure
typedef refcounted(unsigned char) refcounted_t;

refcounted_ptr refcounted_new_ (size_t structSize) {
    refcounted_t *ptr = extc_malloc(structSize);
    ptr->refcount_ = 1;
    return ptr;
}
