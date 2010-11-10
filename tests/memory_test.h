/**
 * libextc memory testcase
 * ExtendedC
 *
 * by Justin Spahr-Summers
 *
 * Released 9. Nov 2010 into the public domain.
 */

#ifndef EXTC_TEST_MEMORY_H
#define EXTC_TEST_MEMORY_H

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include "memory.h"
#include "test.h"

void memory_benchmark (void);
void memory_test (void);

#endif
