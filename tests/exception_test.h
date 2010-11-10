/**
 * libextc exception testcase
 * ExtendedC
 *
 * by Justin Spahr-Summers
 *
 * Released 9. Nov 2010 into the public domain.
 */

#ifndef EXTC_TEST_EXCEPTION_H
#define EXTC_TEST_EXCEPTION_H

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include "exception.h"
#include "test.h"

exception_declaration(TestException);

void exception_benchmark (void);
void exception_test (void);

#endif
