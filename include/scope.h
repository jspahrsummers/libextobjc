/**
 * Automatic scoping and destructor functionality a la scope() in D
 * ExtendedC
 *
 * by Justin Spahr-Summers
 * Copyright (C) 2010
 */

#ifndef EXTC_HEADER_SCOPE_H
#define EXTC_HEADER_SCOPE_H

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include <limits.h>
#include "metamacros.h"

#define SCOPE_DESTRUCTOR_LIMIT 256

enum scope_cleanup_t {
	SCOPE_EXECUTING,
	SCOPE_CLEANING_UP,
	SCOPE_EXITING
};

/**
 * Expands to scope_KEYWORD. Allows usage of the scope macros more like the D
 * language construct.
 *
 * KEYWORD must be one of the following:
 *
 *  new
 *      creates a new scope
 *      (see scope_new)
 *
 *  exit
 *      performs a block when the current scope is exited
 *      (see scope_exit)
 */
#define scope(KEYWORD) \
    scope_ ## KEYWORD

/**
 * Creates a new scope that performs automatic cleanup when exited. Works like
 * a statement, so that it takes a block of code that becomes the scope.
 *
 * Some notes for usage:
 *      - Variables that will be used in cleanup blocks must be declared OUTSIDE
 *        of the scope. They will retain their assigned values.
 *      - Scopes must never contain declarations for variable-length arrays
 *        because of the underlying 'goto' and 'switch' mechanics.
 *      - Only one 'scope_new' can appear in any given function. This
 *        restriction may be removed in future versions.
 *      - It is illegal to 'return' or 'goto' out of a scope. 'sreturn' provides
 *        the functionality of the former.
 */
#define scope_new \
	for (enum scope_cleanup_t scope_cleanup_state_ = SCOPE_EXECUTING;scope_cleanup_state_ != SCOPE_EXITING;scope_cleanup_state_ = SCOPE_EXITING) \
	for (unsigned int scope_jmplines[SCOPE_DESTRUCTOR_LIMIT];scope_cleanup_state_ != SCOPE_EXITING;scope_cleanup_state_ = SCOPE_EXITING) \
	for (scope_jmplines[0] = 0;scope_cleanup_state_ != SCOPE_EXITING;scope_cleanup_state_ = SCOPE_EXITING) \
	for (unsigned short scope_cleanup_count_ = 0, scope_cleanup_index_ = 0;scope_cleanup_state_ != SCOPE_EXITING;scope_cleanup_state_ = SCOPE_EXITING) \
	scope_loop_: \
	for (;scope_cleanup_state_ == SCOPE_EXECUTING || (scope_cleanup_index_ > 0 && scope_cleanup_index_ < SCOPE_DESTRUCTOR_LIMIT);scope_cleanup_state_ = SCOPE_CLEANING_UP, scope_cleanup_index_ = scope_cleanup_count_) \
	switch (scope_jmplines[scope_cleanup_index_]) \
	default:

/**
 * Defines some cleanup code to be executed when the current scope is left.
 * Works just like a statement in that it can take one line, or multiple lines
 * surrounded by braces.
 *
 * Multiple cleanup blocks are executed in lexical order.
 *
 * Some notes for usage:
 *      - Variables that will be used in cleanup blocks must be declared OUTSIDE
 *        of the scope. They will retain their assigned values.
 *      - Scopes must never contain declarations for variable-length arrays
 *        because of the underlying 'goto' and 'switch' mechanics.
 *      - It is illegal to 'return' or 'goto' out of a cleanup block.
 *      - Currently, exceptions cause cleanup blocks to be skipped. This may be
 *        fixed in a future version.
 */
#define scope_exit \
	if ( \
		scope_cleanup_state_ == SCOPE_CLEANING_UP || ( \
			(scope_jmplines[++scope_cleanup_index_] = __LINE__) && \
			++scope_cleanup_count_ && \
			0 \
		) \
	) \
        case __LINE__:                                                      \
            for (bool scope_done_once_ = false;;scope_done_once_ = true)    \
                if (scope_done_once_) {                                     \
                	--scope_cleanup_index_; \
                    goto scope_loop_;                                       \
                } else                                                      \

/**
 * Exits the current scope, runs any cleanup code, and returns the given value
 * (if present).
 *
 * Essentially, this is invoked identically to built-in 'return', but should
 * always be used instead of 'return' inside a scope, and cannot be used outside
 * of one.
 *
 * Although a given sreturn statement may always be executed, the compiler may
 * still issue warnings about your non-void function not returning a value. To
 * suppress these warnings, you can use 'return' with a bogus value at the very
 * end of your function. Many compilers also shut up if you use assert(0); at
 * the very end.
 */
#define sreturn \
    if (scope_cleanup_state_ == SCOPE_EXECUTING) { \
        scope_cleanup_state_ = SCOPE_CLEANING_UP; \
        scope_cleanup_index_ = SCOPE_DESTRUCTOR_LIMIT - scope_cleanup_count_; \
        goto scope_loop_;                           \
    } else if (scope_cleanup_state_ == SCOPE_CLEANING_UP) { \
        --scope_cleanup_index_; \
        goto scope_loop_;                           \
    } else \
        case __LINE__:                              \
            return

#endif
