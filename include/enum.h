/**
 * More versatile enumerations
 * ExtendedC
 *
 * by Justin Spahr-Summers
 * Copyright (C) 2010
 */

#ifndef EXTC_ENUM_H
#define EXTC_ENUM_H

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include <limits.h>
#include <stddef.h>

/**
 * Represents an enumerated value mapped to a string.
 */
struct enum_map_item {
    const char * const name;
    const int code;
};

/**
 * Defines a mapped enum named NAME. Braces and enum_item() invocations should
 * follow.
 */
#define enum_map(NAME) \
    static const struct enum_map_item NAME [] =

/**
 * Maps the enumerated value NAME, which must have been previously declared.
 */
#define enum_item(NAME) \
    {                                                   \
        .name = enum_name_stringify(NAME),              \
        .code = (NAME)                                  \
    }

/**
 * Returns the enumerated value associated with NAME in MAP, or INT_MIN if NAME
 * does not exist in the given MAP.
 *
 * MAP must be an enum_map() previously defined and fully visible in the current
 * scope.
 */
#define enum_from_string(MAP, NAME) \
        enum_from_string_((MAP), sizeof(MAP) / sizeof(struct enum_map_item), (NAME))

/**
 * Returns the string associated with enumerated value CODE in MAP, or NULL if
 * CODE does not exist in the given MAP.
 *
 * MAP must be an enum_map() previously defined and fully visible in the current
 * scope.
 */
#define enum_to_string(MAP, CODE) \
        enum_to_string_  ((MAP), sizeof(MAP) / sizeof(struct enum_map_item), (CODE))

// IMPLEMENTATION DETAILS FOLLOW!
// Do not write code that depends on anything below this line.
#define enum_name_stringify(NAME) \
        enum_name_stringify_(NAME)

#define enum_name_stringify_(NAME) # NAME

int       enum_from_string_ (const struct enum_map_item *items, size_t itemCount, const char *name);

const char *enum_to_string_ (const struct enum_map_item *items, size_t itemCount, int code);

#endif
