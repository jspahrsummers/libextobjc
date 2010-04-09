/**
 * vector(T) template
 * ExtendedC
 *
 * by Justin Spahr-Summers
 * Copyright (C) 2010
 */

#ifndef EXTC_VECTOR_H
#define EXTC_VECTOR_H

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include <stdbool.h>
#include <stddef.h>
#include <string.h>
#include "blocks.h"
#include "template.h"

/**
 * Refers to a vector (dynamic array) containing items of type T.
 */
#define vector(T) \
        vector_(const, T)

/**
 * Generic pointer type for all vectors.
 * This destroys type-checking, so avoid using it!
 */
typedef void *vector_ptr;

/**
 * Generic pointer type for all unmodifiable vectors.
 * This destroys type-checking, so avoid using it!
 */
typedef const void *vector_const_ptr;

/**
 * Creates and returns a new vector of type T.
 * This vector must be freed with vector_delete() when finished.
 */
#define vector_new(T) \
        vector_new_(sizeof(template_type(T)))

/**
 * Deletes the given vector.
 * The caller is responsible for the lifecycle of pointer items in the vector.
 */
void vector_delete (vector_ptr vec);

/**
 * Adds VAL to the end of VEC.
 */
#define vector_add(VEC, VAL) \
        vector_insert((VEC), (VAL), (VEC)->count)

/**
 * Adds COUNT items from ARR to the end of VEC.
 */
#define vector_add_array(VEC, COUNT, ARR) \
        vector_insert_array((VEC), (COUNT), (ARR), (VEC)->count)

/**
 * References the item at INDEX in VEC.
 * Assignment is allowed as long as VEC is not qualified 'const'.
 */
#define vector_at(VEC, INDEX) \
    ((VEC)->items[vector_bounds_check((VEC), (INDEX))].value)

/**
 * Ensures that INDEX is within the bounds of VEC.
 * Returns INDEX if in bounds, throws an OutOfBoundsException otherwise.
 */
#define vector_bounds_check(VEC, INDEX) \
        vector_bounds_check_((VEC), (INDEX), 0)

/**
 * Loops through VEC, assigning each item to VAR and executing the body of the loop.
 * 'break' and 'continue' work normally.
 *
 * ---
 * vector(double) *v = vector_new(double);
 * // put some items in 'v'
 *
 * vector_foreach (double val, v) {
 *      printf("%f\n", val);
 * }
 * ---
 */
#define vector_foreach(VAR, VEC) \
    for (bool done_ = false, oneLoop_; !done_; done_ = true) \
        for (size_t vec_index_ = 0; oneLoop_ = true, !done_ && vec_index_ < (VEC)->count; ++vec_index_) \
            for (VAR = vector_at((VEC), vec_index_); oneLoop_ && (done_ = true); oneLoop_ = false, done_ = false)

/**
 * Loops through VEC, assigning each item to VAR and executing the body of the loop.
 * The index of each item is assigned to a new size_t variable named by IND.
 *
 * ---
 * vector(double) *v = vector_new(double);
 * // put some items in 'v'
 *
 * vector_foreach_index (index, double val, v) {
 *      printf("v[%zu] = %f\n", index, val);
 * }
 * ---
 */
#define vector_foreach_index(IND, VAR, VEC) \
    for (bool done_ = false, oneLoop_; !done_; done_ = true) \
        for (size_t IND, vec_index_ = 0; oneLoop_ = true, !done_ && vec_index_ < (VEC)->count; ++vec_index_) \
            for (VAR = vector_at((VEC), (IND = vec_index_)); oneLoop_ && (done_ = true); oneLoop_ = false, done_ = false)

/**
 * Inserts VAL into vector VEC before index INDEX.
 * If INDEX is greater than the highest-numbered index plus one, throws an IndexOutOfBoundsException.
 */
#define vector_insert(VEC, VAL, INDEX) \
    do {                                                        \
        size_t index_ = vector_prepare_for_insert_((VEC), 1,    \
            vector_bounds_check_((VEC), (INDEX), 1));           \
        vector_at((VEC), index_) = (VAL);                       \
    } while (0)

/**
 * Inserts the COUNT items in ARR into vector VEC before index INDEX.
 * If INDEX is greater than the highest-numbered index plus one, behavior is undefined.
 *
 * The type of items in ARR need not be the same as the type of items in VEC as
 * long as they are implicitly convertible.
 */
#define vector_insert_array(VEC, COUNT, ARR, INDEX) \
    do {                                                                    \
        if (!(COUNT))                                                       \
            break;                                                          \
                                                                            \
        size_t start_ = vector_prepare_for_insert_((VEC), (COUNT),          \
            vector_bounds_check_((VEC), (INDEX), (COUNT)));                 \
        /* memcpy() cannot be used because 'items' might have padding */    \
        for (size_t index_ = 0; index_ < (COUNT); ++index_)                 \
            vector_at((VEC), index_ + start_) = (ARR)[index_];              \
    } while (0)

/**
 * Removes the item at INDEX in VEC.
 */
#define vector_remove(VEC, INDEX) \
        vector_remove_range((VEC), (INDEX), 1)

/**
 * Removes the LENGTH items starting at INDEX in VEC.
 */
#define vector_remove_range(VEC, INDEX, LENGTH) \
        vector_remove_range_((VEC), vector_bounds_check_((VEC), (INDEX), (LENGTH)), (LENGTH))

// IMPLEMENTATION DETAILS FOLLOW!
// Do not write code that depends on anything below this line.
#define vector_(C, T) \
    struct {                                    \
        C size_t itemSize_;                     \
        C size_t count;                         \
        C size_t capacity;                      \
        int (*compare)(const T a, const T b);   \
        template_type(T) * C items;             \
    }

vector_ptr vector_new_ (size_t itemSize);

#define vector_bounds_check_(VEC, INDEX, TOLERANCE) \
        vector_bounds_check_or_raise_((VEC), (VEC)->count + (TOLERANCE), (INDEX), __func__, __FILE__, __LINE__)

size_t vector_bounds_check_or_raise_ (vector_const_ptr vec, size_t countToUse, size_t index, const char *func, const char *file, unsigned long line);

size_t vector_prepare_for_insert_ (vector_ptr vec, size_t count, size_t index);

void vector_remove_range_ (vector_ptr vec, size_t start, size_t length);

#endif
