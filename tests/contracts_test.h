/**
 * libextc contracts testcase
 * ExtendedC
 *
 * by Justin Spahr-Summers
 * Copyright (C) 2010
 */

#ifndef EXTC_TEST_CONTRACTS_H
#define EXTC_TEST_CONTRACTS_H

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

// NDEBUG can't be defined for contracts to work as intended
#undef NDEBUG

#include "contracts.h"
#include "test.h"

void contracts_test (void);

#endif
