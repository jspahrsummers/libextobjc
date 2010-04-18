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
    /* the next few loops initialize variables */                           \
    for (bool scope_cleaned_up_ = false; ! scope_cleaned_up_ ;              \
        scope_cleaned_up_ = true)                                           \
    for (bool scope_cleaning_up_ = false; ! scope_cleaned_up_ ;             \
        scope_cleaned_up_ = true)                                           \
    for (unsigned long scope_first_clean_ = ULONG_MAX;                      \
        ! scope_cleaned_up_ ; scope_cleaned_up_ = true)                     \
    for (unsigned long scope_last_clean_ = ULONG_MAX;                       \
        ! scope_cleaned_up_ ; scope_cleaned_up_ = true)                     \
    for (unsigned long scope_return_from_ = ULONG_MAX;                      \
        ! scope_cleaned_up_ ; scope_cleaned_up_ = true)                     \
    for (unsigned long scope_jump_to_ = 0;                                  \
        ! scope_cleaned_up_ ; scope_cleaned_up_ = true)                     \
                                                                            \
    /* create a label for jumping outside the enclosing loop */             \
    scope_exit_ :                                                           \
                                                                            \
    /* enclosing loop to automatically clean up */                          \
    for (; ! scope_cleaned_up_ ; scope_cleaning_up_                         \
        = true, scope_jump_to_ =                                            \
        scope_first_clean_)                                                 \
                                                                            \
    /* create a label to provide 'continue'-like functionality */           \
    scope_loop_:                                                            \
                                                                            \
    /* jump to normal or cleanup code */                                    \
    switch (scope_jump_to_)                                                 \
        /* if no cleanup label is found */                                  \
        default:                                                            \
            if (scope_cleaning_up_) {                                       \
                /* if there are still more cleanup handlers */              \
                if (scope_first_clean_ != ULONG_MAX &&                      \
                    scope_jump_to_ <                                        \
                    scope_last_clean_)                                      \
                    /* iterate until we hit the next one */                 \
                    ++scope_jump_to_;                                       \
                else {                                                      \
                    /* break out */                                         \
                    scope_cleaned_up_ = true;                               \
                    if (scope_return_from_ == ULONG_MAX)                    \
                        /* 'sreturn' wasn't used, so just exit the loop */  \
                        goto scope_exit_;                                   \
                                                                            \
                    /* jump back to where 'sreturn' was used */             \
                    scope_jump_to_ =                                        \
                        scope_return_from_;                                 \
                }                                                           \
                                                                            \
                /* redo the jump */                                         \
                goto scope_loop_;                                           \
            } else                                                          \
                /* user code */

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
 *      - It is illegal to 'return', 'sreturn', or 'goto' out of a cleanup
 *        block.
 *      - Currently, exceptions cause cleanup blocks to be skipped. This WILL be
 *        fixed in a future version.
 */
#define scope_exit \
    if (scope_cleaning_up_ ||                                               \
        /* if not currently cleaning up, make sure to set the jump points   \
           for the first and last cleanup blocks */                         \
        !exprify(scope_last_clean_ = __LINE__,                              \
        (scope_first_clean_ == ULONG_MAX ?                                  \
            scope_first_clean_ = __LINE__                                   \
            : 0                                                             \
        ))                                                                  \
    )                                                                       \
        /* eventually jumps here if cleaning up */                          \
        case __LINE__:                                                      \
            /* loop to execute user code then do something else */          \
            for (bool scope_done_once_ = false;;scope_done_once_ = true)    \
                if (scope_done_once_) {                                     \
                    /* if the cleanup code finished, continue onward */     \
                    ++scope_jump_to_;                                       \
                    goto scope_loop_;                                       \
                } else                                                      \
                    /* user cleanup code */

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
    if (!scope_cleaning_up_) {                      \
        /* if not currently cleaning up, do that */ \
        scope_cleaning_up_ = true;                  \
        scope_jump_to_ = scope_first_clean_;        \
        scope_return_from_ = __LINE__;              \
        goto scope_loop_;                           \
    } else                                          \
        /* cleanup finished, now actually return */ \
        case __LINE__:                              \
            return

#endif
