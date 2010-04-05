/**
 * vector(T) template
 * ExtendedC
 *
 * by Justin Spahr-Summers
 * Copyright (C) 2010
 */

#include <assert.h>
#include <stdio.h>
#include <string.h>
#include "memory.h"
#include "vector.h"

/**
 * Multiplier for vector size when a greater capacity is needed
 */
#define VECTOR_RESIZE_FACTOR 2

// used for accessing the fields in the structure
typedef vector_(, unsigned char) vector_t;

vector_ptr vector_new_ (size_t itemSize) {
    vector_t *ptr = extc_calloc(1, sizeof(*ptr));
    ptr->itemSize_ = itemSize;
    ptr->items = NULL;
    return ptr;
}

void vector_delete (vector_ptr vec) {
    if (vec) {
        vector_t *ptr = vec;
        assert(ptr != NULL);
        
        extc_free(ptr->items);
        
        #ifdef DEBUG
        // minimize the problems caused by dangling references
        // in other words, cause instantly recognizable crashes
        ptr->count      = SIZE_MAX;
        ptr->capacity   = SIZE_MAX;
        ptr->items = NULL;
        #endif
    
        extc_free(ptr);
    }
}

size_t vector_prepare_for_insert_ (vector_ptr vec, size_t index) {
    vector_t *ptr = vec;
    assert(ptr != NULL);
    
    if (ptr->capacity <= ptr->count) {
        size_t newCapacity = (ptr->capacity ? ptr->capacity * VECTOR_RESIZE_FACTOR : 1);
        ptr->items = extc_realloc(ptr->items, ptr->itemSize_ * newCapacity);
        ptr->capacity = newCapacity;
    }
    
    if (index < ptr->count) {
        unsigned char *itemsPtr = (void *)ptr->items;
        memmove(itemsPtr + ptr->itemSize_ * (index + 1),
                itemsPtr + ptr->itemSize_ *  index     , ptr->itemSize_);
    }
    
    ++ptr->count;
    return index;
}

void vector_remove (vector_ptr vec, size_t index) {
    vector_t *ptr = vec;
    assert(ptr != NULL);
    
    if (index + 1 < ptr->count) {
        unsigned char *itemsPtr = (void *)ptr->items;
        memmove(itemsPtr + ptr->itemSize_ * index,
                itemsPtr + ptr->itemSize_ * (index + 1), ptr->itemSize_);
    }
    
    --ptr->count;
}
