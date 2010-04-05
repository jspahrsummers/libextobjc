/**
 * Memory utilities
 * ExtendedC
 *
 * by Justin Spahr-Summers
 * Copyright (C) 2010
 */

#ifndef EXTC_MEMORY_H
#define EXTC_MEMORY_H

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include <stdio.h>
#include <stdlib.h>
#include "exceptions.h"

/**
 * Exception thrown if memory could not be allocated.
 *
 * The 'data' field is set to the pointer being reallocated with extc_realloc()
 * if that was the function being used, or NULL otherwise.
 */
exception_declaration(MemoryException);

/**
 * Allocates 'count' objects of 'size' bytes, zeroes the memory, and returns a
 * pointer to it.
 *
 * A MemoryException will be thrown if there was an error allocating memory.
 * NULL will never be returned.
 */
void *extc_calloc (size_t count, size_t size);

/**
 * Convenience macro for free() for uniformity with the other functions here.
 * This may be updated later to do something amazing.
 */
#define extc_free(p) free(p)

/**
 * Allocates 'size' bytes of memory and returns a pointer to it.
 *
 * A MemoryException will be thrown if there was an error allocating memory.
 * NULL will never be returned.
 */
void *extc_malloc (size_t size);

/**
 * Swaps the first 'size' bytes of the data pointed to by 'ptrA' and 'ptrB'.
 * The swap is done in a completely portable manner, and with O(1) additional storage.
 */
void extc_memswap (void * restrict ptrA, void * restrict ptrB, size_t size);

/**
 * Resizes the allocation pointed to by 'ptr' to be 'size' bytes and returns a
 * (possibly different) pointer to it. The contents will the same up to the
 * lesser of the new and old sizes.
 *
 * If 'ptr' is NULL, this behaves exactly like extc_malloc().
 *
 * A MemoryException will be thrown if there was an error allocating memory.
 * NULL will never be returned.
 */
void *extc_realloc (void *ptr, size_t size);

/**
 * Resizes the allocation pointed to by 'ptr' to be 'size' bytes and returns a
 * (possibly different) pointer to it. The contents will the same up to the
 * lesser of the new and old sizes.
 *
 * If 'ptr' is NULL, this behaves exactly like extc_malloc().
 *
 * A MemoryException will be thrown if there was an error allocating memory.
 * In addition, 'ptr' will be freed in such a case.
 * NULL will never be returned.
 */
void *extc_reallocf (void *ptr, size_t size);

#endif
