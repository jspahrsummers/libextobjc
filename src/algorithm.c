/**
 * Generally useful algorithms
 * ExtendedC
 *
 * by Justin Spahr-Summers
 * Copyright (C) 2010
 */

#include <math.h>
#include <string.h>
#include "algorithm.h"
#include "memory.h"

// when the length of data to be sorted is at or below this threshold,
// switch to insertion sort
#define ALGORITHM_INTROSORT_THRESHOLD 16

/*** Private types ***/
struct algorithm_sort_info {
    size_t itemSize;
    size_t valueSize;
    int (*compare)(const void *, const void *, size_t);
};

/*** Private functions ***/
static
void algorithm_heapsort_sift (unsigned char * restrict data, size_t root, size_t count, struct algorithm_sort_info info, unsigned char * restrict buffer);

static
void algorithm_introsort_loop (unsigned char *data, size_t count, struct algorithm_sort_info info, unsigned depth_limit);

void algorithm_heapsort (void *base, size_t count, size_t itemSize, size_t valueSize, int (*compare)(const void *, const void *, size_t)) {
    size_t i;
    struct algorithm_sort_info info = {
        .itemSize = itemSize,
        .valueSize = valueSize,
        .compare = compare
    };
    
    unsigned char buffer[itemSize];
    for (i = count;i > 0;--i)
        algorithm_heapsort_sift(base, i - 1, count - 1, info, buffer);
    
    unsigned char *data = base;
    for (i = count - 1;i >= 1;--i) {
        memcpy(buffer             , data               , itemSize);
        memcpy(data               , data + i * itemSize, itemSize);
        memcpy(data + i * itemSize, buffer             , itemSize);
        algorithm_heapsort_sift(data, 0, i - 1, info, buffer);
    }
}

static
void algorithm_heapsort_sift (unsigned char * restrict data, size_t root, size_t count, struct algorithm_sort_info info, unsigned char * restrict buffer) {
    size_t maxChild;
    while (root * 2 <= count) {
        if (root * 2 == count || info.compare(
            data +  root * 2      * info.itemSize,
            data + (root * 2 + 1) * info.itemSize,
            info.valueSize
        ) > 0)
            maxChild = root * 2;
        else
            maxChild = root * 2 + 1;
        
        if (info.compare(data + root * info.itemSize, data + maxChild * info.itemSize, info.valueSize) < 0) {
            memcpy(buffer                         , data + root     * info.itemSize, info.itemSize);
            memcpy(data + root     * info.itemSize, data + maxChild * info.itemSize, info.itemSize);
            memcpy(data + maxChild * info.itemSize, buffer                         , info.itemSize);
            
            root = maxChild;
        } else
            break;
    }
}

void algorithm_introsort (void *base, size_t count, size_t itemSize, size_t valueSize, int (*compare)(const void *, const void *, size_t)) {
    algorithm_introsort_loop(base, count, (struct algorithm_sort_info){
        .itemSize = itemSize,
        .valueSize = valueSize,
        .compare = compare
    }, (unsigned)log2(count));
    
    // todo: insertion sort
}

static
void algorithm_introsort_loop (unsigned char *data, size_t count, struct algorithm_sort_info info, unsigned depth_limit) {
    while (count > ALGORITHM_INTROSORT_THRESHOLD) {
        if (depth_limit == 0) {
            algorithm_heapsort(data, count, info.itemSize, info.valueSize, info.compare);
            return;
        }
        
        // todo: finish this
    }
}
