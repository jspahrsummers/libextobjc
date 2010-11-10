/**
 * libextc refcounted testcase
 * ExtendedC
 *
 * by Justin Spahr-Summers
 *
 * Released 9. Nov 2010 into the public domain.
 */

#ifndef EXTC_TEST_REFCOUNTED_H
#define EXTC_TEST_REFCOUNTED_H

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include "refcounted.h"
#include "test.h"

void refcounted_benchmark (void);
void refcounted_test (void);

#endif
