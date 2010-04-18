/**
 * libextc testcase helper functions
 * ExtendedC
 *
 * by Justin Spahr-Summers
 * Copyright (C) 2010
 */

#ifndef EXTC_TEST_TEST_H
#define EXTC_TEST_TEST_H

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include <assert.h>
#include <limits.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define LOG_TEST(...) \
        LOG_TEST_(__VA_ARGS__, 0)

#define LOG_TEST_(MSG, ...) \
    printf(__FILE__ ":%lu (%s): " MSG "\n", (unsigned long)__LINE__, __func__, __VA_ARGS__)

#define TEST_MODULE(NAME) \
    (                                                               \
        printf("*** Testing module %s ***\n", # NAME),              \
        NAME ## _test(),                                            \
        printf("*** %s module passed all tests! ***\n\n", # NAME)   \
    )

#endif
