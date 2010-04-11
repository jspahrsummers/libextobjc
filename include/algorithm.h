/**
 * Generally useful algorithms
 * ExtendedC
 *
 * by Justin Spahr-Summers
 * Copyright (C) 2010
 */

#ifndef EXTC_ALGORITHM_H
#define EXTC_ALGORITHM_H

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include <stddef.h>

/**
 * Sorts an array of 'count' objects, of 'itemSize' bytes apiece, pointed to by
 * 'base'. The contents are sorted into ascending order according to the results
 * of the 'compare' function invoked with two objects and 'valueSize'.
 *
 * The relative order of two equal items may not be preserved when sorting.
 *
 * The algorithm used is heapsort, which has a consistent O(n log n) complexity
 * for all cases, but in practice may not be as quick as quicksort or introsort.
 */
void algorithm_heapsort (void *base, size_t count, size_t itemSize, size_t valueSize, int (*compare)(const void *, const void *, size_t));

/**
 * Sorts an array of 'count' objects, of 'itemSize' bytes apiece, pointed to by
 * 'base'. The contents are sorted into ascending order according to the results
 * of the 'compare' function invoked with two objects and 'valueSize'.
 *
 * The relative order of two equal items may not be preserved when sorting.
 *
 * The algorithm used is introsort, which has performance comparable to
 * quicksort, but without an O(n^2) worst case.
 */
void algorithm_introsort (void *base, size_t count, size_t itemSize, size_t valueSize, int (*compare)(const void *, const void *, size_t));

#endif
