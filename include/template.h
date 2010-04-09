/**
 * Template support facilities
 * ExtendedC
 *
 * by Justin Spahr-Summers
 * Copyright (C) 2010
 */

#ifndef EXTC_TEMPLATE_H
#define EXTC_TEMPLATE_H

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include "exceptions.h"

/*
 * N1256 6.2.6:
 * "All pointers to union types shall have the same representation and alignment
 *  requirements as each other. Pointers to other types need not have the same
 *  representation or alignment requirements."
 *
 * Therefore, we use a meaningless union when we need pointers that can be
 * accessed and modified without knowing the templated type (but knowing its
 * size).
 *
 * On all platforms I know of, unions do not have trailing padding (though such
 * is technically allowed), so this does not incur any overhead.
 */
#define template_type(T) \
    union {                     \
        unsigned char unused_;  \
        T value;                \
    }

/**
 * Exception thrown by ExtendedC templates when a given index is out-of-bounds.
 *
 * The 'data' field is set to the templated container.
 */
exception_declaration(IndexOutOfBoundsException);

#endif
