/**
 * Design by contract facilities
 * ExtendedC
 *
 * by Justin Spahr-Summers
 * Copyright (C) 2010
 */

#ifndef EXTC_HEADER_CONTRACTS_H
#define EXTC_HEADER_CONTRACTS_H

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include <assert.h>
#include <stdbool.h>
#include "metamacros.h"

/**
 * Declares a contract for FUNC. RETTYPE must be the return type of the function,
 * and any arguments must follow FUNC in the macro invocation.
 *
 * Within the contract, body() can be used to execute the implementation of the
 * function. There must always be an 'in' statement within a contract.
 *
 * Example:
 *
 * 	contract(void *, allocate_memory, size_t sz) {
 * 		in {
 * 			assert(sz <= 1024);
 * 		}
 * 		
 * 		void *ret = body(sz);
 * 		out {
 * 			assert(ret != NULL);
 * 		}
 * 		
 * 		return ret;
 * 	}
 *
 * The function definition (which may be in another file) should be implemented
 * as normal, except with the name changed to FUNC_body() - for example, a
 * contract on foobar() means that foobar's implementation should actually go
 * into a function named foobar_body().
 */
#define contract(RETTYPE, FUNC, ...) \
	RETTYPE FUNC ## _body ( __VA_ARGS__ ); \
	\
	static inline	\
	RETTYPE FUNC ( __VA_ARGS__ ) {	\
		RETTYPE (*body)(__VA_ARGS__) = & FUNC ## _body ;

#ifndef NDEBUG
	/**
	 * Defines and documents assumptions about the function's arguments.
	 *
	 * One of these statements must always be present (even if empty),
	 * regardless of whether the function actually has arguments.
	 */
	#define in \
			}
	
	/**
	 * Defines and documents assumptions about the function's return value. This
	 * statement is optional.
	 */
	#define out
#else
	// disable execution of contracts if NDEBUG is defined
	#define in \
		}	\
		\
		if (0)
	
	#define out \
		if (0)
#endif

#endif
