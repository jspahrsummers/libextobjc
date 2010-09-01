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

#define contract(RETTYPE, FUNC, ...) \
	RETTYPE FUNC ## _body ( __VA_ARGS__ ); \
	\
	static inline	\
	RETTYPE FUNC ( __VA_ARGS__ ) {	\
		RETTYPE (*body)(__VA_ARGS__) = & FUNC ## _body ;

#ifdef NDEBUG
	#define in \
		}	\
		\
		if (0)
	
	#define out(VALUE) \
		if (0)
#else
	#define in \
			}
	
	#define out(VALUE)
#endif

#endif
