/**
 * vector(T) template
 * ExtendedC
 *
 * by Justin Spahr-Summers
 * Copyright (C) 2010
 */

#include <assert.h>
#include <stdio.h>
#include "algorithm.h"
#include "memory.h"
#include "vector.h"

/**
 * Multiplier for vector size when a greater capacity is needed
 */
#define VECTOR_RESIZE_FACTOR 2

// used for accessing the fields in the structure
typedef vector_(, unsigned char) vector_t;

vector_ptr vector_new_ (size_t valueSize, size_t itemSize) {
    // calloc is used to not only initialize some fields
    // but also to make sure any padding bits are set to 0 for bit comparisons
    vector_t *ptr = extc_calloc(1, sizeof(*ptr));
    ptr->itemSize_ = itemSize;
    ptr->valueSize_ = valueSize;
    ptr->items = NULL;
    ptr->compare = &memcmp;
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

size_t vector_bounds_check_or_raise_ (vector_const_ptr restrict vec, size_t countToUse, size_t index, const char *func, const char *file, unsigned long line) {
    assert(vec != NULL);

    if (index >= countToUse)
        exception_raise_(NULL, IndexOutOfBoundsException, vec, func, file, line);
    
    return index;
}

size_t vector_prepare_for_insert_ (vector_ptr vec, size_t count, size_t index) {
    vector_t *ptr = vec;
    assert(ptr != NULL);
    
    if (ptr->capacity < ptr->count + count) {
        size_t newCapacity = (ptr->capacity ? ptr->capacity * VECTOR_RESIZE_FACTOR : 1);
        while (newCapacity < ptr->count + count)
            // this isn't shorthanded so that VECTOR_RESIZE_FACTOR can be something like 3 / 2
            newCapacity = newCapacity * VECTOR_RESIZE_FACTOR;
        
        ptr->items = extc_realloc(ptr->items, ptr->itemSize_ * newCapacity);
        ptr->capacity = newCapacity;
    }
    
    if (index < ptr->count) {
        unsigned char *itemsPtr = (void *)ptr->items;
        memmove(itemsPtr + ptr->itemSize_ * (index + count),
                itemsPtr + ptr->itemSize_ *  index         , ptr->itemSize_ * count);
    }
    
    ptr->count += count;
    return index;
}

void vector_remove_range_ (vector_ptr vec, size_t start, size_t length) {
    vector_t *ptr = vec;
    assert(ptr != NULL);
    
    if (start + length < ptr->count) {
        unsigned char *itemsPtr = (void *)ptr->items;
        memmove(itemsPtr + ptr->itemSize_ *  start,
                itemsPtr + ptr->itemSize_ * (start + length), ptr->itemSize_);
    }
    
    ptr->count -= length;
}

bool vector_search (vector_const_ptr vec, const void *item, size_t *index) {
    const vector_t *ptr = vec;
    assert(ptr != NULL);
    assert(ptr->compare != NULL);
    
    for (size_t i = 0;i < ptr->count;++i) {
        // valueSize_ is needed here to prevent possible padding from being considered
        if (ptr->compare(item, ptr->items + i, ptr->valueSize_) == 0) {
            if (index)
                *index = i;
            
            return true;
        }
    }
    
    return false;
}

void vector_unstable_sort (vector_ptr vec) {
    vector_t *ptr = vec;
    assert(ptr != NULL);
    
    algorithm_introsort(ptr->items, ptr->count, ptr->itemSize_, ptr->valueSize_, ptr->compare);
}
