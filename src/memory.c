/**
 * Memory utilities
 * ExtendedC
 *
 * by Justin Spahr-Summers
 * Copyright (C) 2010
 */

#include <string.h>
#include "memory.h"

// the maximum amount of memory swapped per cycle with extc_memswap()
#define MEMORY_SWAP_BLOCK_SIZE (sizeof(unsigned int) * 4)

/*** Exception types ***/
exception_subclass(Exception, MemoryException);

void *extc_calloc (size_t count, size_t size) {
    void *ptr = calloc(count, size);
    if (!ptr)
        raise(MemoryException, NULL);
    
    return ptr;
}

void extc_free (void *ptr) {
    free(ptr);
}

void *extc_malloc (size_t size) {
    void *ptr = malloc(size);
    if (!ptr)
        raise(MemoryException, NULL);
    
    return ptr;
}

void extc_memswap (void * restrict ptrA, void * restrict ptrB, size_t size) {
    unsigned char * restrict a = ptrA;
    unsigned char * restrict b = ptrB;
    unsigned char buffer      [MEMORY_SWAP_BLOCK_SIZE];

    while (size >=             MEMORY_SWAP_BLOCK_SIZE) {
        memcpy(buffer, a     , MEMORY_SWAP_BLOCK_SIZE);
        memcpy(a     , b     , MEMORY_SWAP_BLOCK_SIZE);
        memcpy(b     , buffer, MEMORY_SWAP_BLOCK_SIZE);
        
        a       +=             MEMORY_SWAP_BLOCK_SIZE;
        b       +=             MEMORY_SWAP_BLOCK_SIZE;
           size -=             MEMORY_SWAP_BLOCK_SIZE;
    }

    if (size > 0) {
        memcpy(buffer, a     , size);
        memcpy(a     , b     , size);
        memcpy(b     , buffer, size);
    }
}

void *extc_realloc (void *ptr, size_t size) {
    void *newptr = realloc(ptr, size);
    if (!newptr)
        raise(MemoryException, ptr);
    
    return newptr;
}

void *extc_reallocf (void *ptr, size_t size) {
    void *newptr = realloc(ptr, size);
    if (!newptr) {
        free(ptr);
        raise(MemoryException, NULL);
    }
    
    return newptr;
}
