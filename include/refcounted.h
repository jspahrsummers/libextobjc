/**
 * refcounted(T) template
 * ExtendedC
 *
 * by Justin Spahr-Summers
 * Copyright (C) 2010
 */

#ifndef EXTC_REFCOUNTED_H
#define EXTC_REFCOUNTED_H

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include <stddef.h>

/**
 * The type to use for reference counts.
 */
typedef unsigned long refcount_t;

/**
 * A structure that manages the reference count for an object of type T.
 */
#define refcounted(T) \
    struct {                    \
        refcount_t refcount_;   \
        T value;                \
    }

/**
 * Generic pointer type for all reference-counted objects.
 * This destroys type-checking, so avoid using it!
 */
typedef void *refcounted_ptr;

/**
 * Creates and returns a new reference-counted object of type T.
 * This object must be released with release() when finished.
 */
#define refcounted_new(T) \
        refcounted_new_(sizeof(refcounted(T)))

/**
 * Releases variable REF from the caller's ownership and sets it to NULL.
 */
#define release(REF) \
    ((void)(--(REF)->refcount_, (REF) = NULL))

/**
 * Retains object REF for the caller's use.
 * Every retain() must be met with a matching release().
 *
 * Returns REF.
 */
#define retain(REF) \
    (++(REF)->refcount_, (REF))

// IMPLEMENTATION DETAILS FOLLOW!
// Do not write code that depends on anything below this line.
refcounted_ptr refcounted_new_ (size_t structSize);

#endif
