/**
 * libextc exceptions testcase
 * ExtendedC
 *
 * by Justin Spahr-Summers
 * Copyright (C) 2010
 */

#ifndef EXTC_TEST_EXCEPTIONS_H
#define EXTC_TEST_EXCEPTIONS_H

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include "exceptions.h"

exception_declaration(TestException);

void exceptions_test (void);

#endif
