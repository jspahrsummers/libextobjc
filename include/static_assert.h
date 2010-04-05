/**
 * Compile-time assertions
 * ExtendedC
 *
 * by Justin Spahr-Summers
 * Copyright (C) 2010
 */

#ifndef EXTC_HEADER_STATIC_ASSERT
#define EXTC_HEADER_STATIC_ASSERT

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

/**
 * Asserts at compile-time that COND is true, aborting compilation if not.
 * COND must be evaluatable at compile-time.
 */
#define static_assert(COND) \
    extern int static_assertion_FAILED[((long)(COND)) ? 1 : -1]

#endif
