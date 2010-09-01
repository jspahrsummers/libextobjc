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

#include <stdbool.h>
#include "contracts.h"
#include "test.h"

void contracts_test (void);

// contracts aren't supposed to return success or failure
// we just don't want an assertion to bring down the whole test rig
contract(bool, in_test, int value) {
	in {
		if (value != 5)
			return false;
	}
	
	body(value);
	return true;
}

contract(void *, out_test, size_t sz) {
	in {
		assert(sz <= 1024);
	}
	
	void *ret = body(sz);
	out {
		assert(ret != NULL);
	}
	
	return ret;
}

#endif
