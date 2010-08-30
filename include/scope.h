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
#include <stdbool.h>
#include <string.h>
#include "metamacros.h"

#define SCOPE_DESTRUCTOR_LIMIT 128

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
 *	new
 *		creates a new scope
 *		(see scope_new)
 *
 *	exit
 *		performs a block when the current scope is exited
 *		(see scope_exit)
 */
#define scope(KEYWORD) \
	scope_ ## KEYWORD

/**
 * Creates a new scope that performs automatic cleanup when exited. Works like
 * a statement, in that it takes a block of code that becomes the scope.
 *
 * Some notes for usage:
 *		- Variables that will be used in cleanup blocks must be declared OUTSIDE
 *		  of the scope. They will retain their assigned values.
 *		- Scopes must never contain declarations for variable-length arrays
 *		  because of the underlying 'goto' and 'switch' mechanics.
 *		- Only one 'scope_new' can appear in any given function. This
 *		  restriction may be removed in future versions.
 *		- It is illegal to 'return' or 'goto' out of a scope. 'sreturn' provides
 *		  the functionality of the former.
 */
#define scope_new \
	/* set up the state variable that indicates what the scope is doing */	\
	for (enum scope_cleanup_t scope_cleanup_state_ = SCOPE_EXECUTING;	\
		scope_cleanup_state_ != SCOPE_EXITING;	\
		scope_cleanup_state_	= SCOPE_EXITING)	\
	/* set up an array for the line numbers of scope(exit) statements */	\
	/* jmplines is actually a stack so that cleanup is done in reverse */	\
	for (unsigned int scope_jmplines_[SCOPE_DESTRUCTOR_LIMIT];	\
		scope_cleanup_state_ != SCOPE_EXITING;	\
		scope_cleanup_state_	= SCOPE_EXITING)	\
	/* initialize the first "line" with 0 so it always enters default: */	\
	for (scope_jmplines_[0] = 0;	\
		scope_cleanup_state_ != SCOPE_EXITING;	\
		scope_cleanup_state_	= SCOPE_EXITING)	\
	/* set up variables for positioning in the lines array */	\
	for (unsigned short scope_cleanup_count_ = 0, scope_cleanup_index_ = 0;	\
		scope_cleanup_state_ != SCOPE_EXITING;	\
		scope_cleanup_state_	= SCOPE_EXITING)	\
	\
	/* label this spot so exit blocks can jump out, then in to the next one */	\
	/* unfortunately, this does prevent multiple scopes from existing */	\
	scope_loop_:	\
		/* this loop does two things:
			- if the scope has yet to execute, it executes it once
			- if the scope has yet to clean up, it jumps to each cleanup block
		*/	\
		for (;	\
			/* loop while executing or there are still cleanup blocks to hit */	\
			scope_cleanup_state_ == SCOPE_EXECUTING || (	\
				/* include index 0 if it's the location for an sreturn statement */	\
				(scope_cleanup_index_ > 0 || scope_jmplines_[0] != 0) &&	\
				scope_cleanup_index_ < SCOPE_DESTRUCTOR_LIMIT	\
			);	\
			/* after one full execution, change state to start cleaning up */ \
			scope_cleanup_state_ = SCOPE_CLEANING_UP,	\
			scope_cleanup_index_ = scope_cleanup_count_)	\
		/* jump to the appropriate exit block, or default: if not cleaning */	\
		switch (scope_jmplines_[scope_cleanup_index_])	\
		default:	\
			/* normal execution flow begins here */	\
			/* 'break' or 'continue' will exit the switch and begin cleanup */

/**
 * Defines some cleanup code to be executed when the current scope is left.
 * Works just like a statement in that it can take one line, or multiple lines
 * surrounded by braces.
 *
 * Multiple cleanup blocks are executed in reverse lexical order.
 *
 * Some notes for usage:
 *		- Variables that will be used in cleanup blocks must be declared OUTSIDE
 *		  of the scope. They will retain their assigned values.
 *		- It is illegal to 'return' or 'goto' out of a cleanup block.
 *		- Currently, exceptions cause cleanup blocks to be skipped. This may be
 *		  fixed in a future version.
 */
#define scope_exit \
	/* this if statement will only ever get hit during normal flow */	\
	if ( \
		/* mark this spot for jumping during cleanup */	\
		(scope_jmplines_[++scope_cleanup_index_] = __LINE__) && \
		/* increment the number of cleanup blocks */ \
		++scope_cleanup_count_ && \
		/* and, of course, don't actually enter this statement */ \
		0 \
	) \
		/* execution will jump straight here during cleanup */	\
		case __LINE__:	\
			/* meaningless outer loop to allow the use of 'break' */	\
			for (bool scope_done_once_ = false;;scope_done_once_ = true)	\
				/* executes this block of code only once */	\
				for (;;scope_done_once_ = true)	\
					/* if finished... */	\
					if (scope_done_once_) {	\
						/* mark this cleanup block as being finished */	\
						--scope_cleanup_index_;	\
						/* return to the loop so the next one will be done */	\
						goto scope_loop_;	\
					} else	\
						/* cleanup code begins here */

/**
 * Exits the current scope, runs any cleanup code, and returns the given value
 * (if present).
 *
 * Essentially, this is invoked identically to built-in 'return', but should
 * always be used instead of 'return' inside a scope, and cannot be used outside
 * of one.
 *
 * sreturn is legal within scope(exit) blocks. The final sreturn statement that
 * is executed provides the value that is actually returned to the caller.
 *
 * Although a given sreturn statement may always be executed, the compiler may
 * still issue warnings about your non-void function not returning a value. To
 * suppress these warnings, you can use 'return' with a bogus value at the very
 * end of your function. Many compilers also shut up if you use assert(0); at
 * the very end.
 */
#define sreturn \
	/* if there are cleanup blocks... */	\
	if (scope_cleanup_count_) {	\
		/* we need to mark this spot to return to after all the cleanup */	\
		/* subvert the stack and insert this line in the logically last spot */	\
		scope_jmplines_[0] = __LINE__;	\
		\
		/* if already cleaning up (meaning this is within a cleanup block)... */	\
		if (scope_cleanup_state_ == SCOPE_CLEANING_UP) { \
			/* jump to the next cleanup block now that this spot is marked */	\
			--scope_cleanup_index_;	\
		} else {	\
			/* otherwise, start all the normal cleanup logic */	\
			scope_cleanup_state_ = SCOPE_CLEANING_UP;	\
			scope_cleanup_index_ = scope_cleanup_count_;	\
		}	\
		\
		goto scope_loop_;	\
	/* otherwise, actually exit the function */	\
	} else	\
		/* mark this point for jumping if we have cleanup */	\
		case __LINE__:	\
			/* pass on the user's return value */	\
			return

#endif
