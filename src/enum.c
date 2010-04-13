/**
 * More versatile enumerations
 * ExtendedC
 *
 * by Justin Spahr-Summers
 * Copyright (C) 2010
 */

#include <string.h>
#include "enum.h"

int       enum_from_string_ (const struct enum_map_item *items, size_t itemCount, const char *name) {
    for (size_t i = 0;i < itemCount;++i) {
        if (items[i].name == name || strcmp(items[i].name, name) == 0)
            return items[i].code;
    }
    
    return INT_MIN;
}

const char *enum_to_string_ (const struct enum_map_item *items, size_t itemCount, int code) {
    for (size_t i = 0;i < itemCount;++i) {
        if (items[i].code == code)
            return items[i].name;
    }
    
    return NULL;
}
