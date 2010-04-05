/**
 * Language constructs for blocks
 * ExtendedC
 *
 * Unless otherwise specified for a given macro, statements can appear
 * immediately after these macros and work as expected. Braces are optional for
 * single statements, just like built-in constructs.
 *
 * by Justin Spahr-Summers
 * Copyright (C) 2010
 */

#ifndef EXTC_BLOCKS_H
#define EXTC_BLOCKS_H

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

/**
 * Defines a block that will execute the given one or more expressions only if
 * it is broken out of through use of the 'break' keyword.
 */
#define breakable_block(...) \
    for (bool breakable_block_done_ = false; !breakable_block_done_;        \
        breakable_block_done_ = (breakable_block_done_ ||                   \
        exprify(__VA_ARGS__)))                                              \
        for (; !breakable_block_done_; breakable_block_done_ = true)

/**
 * Executes the given block of code, then executes the one or more expressions
 * passed (which may have a void type).
 *
 * This is invaluable for keeping resource acquisition and freeing together.
 */
#define execute_after(...) \
    for (bool execute_after_done_ = false; !execute_after_done_;    \
        execute_after_done_ = exprify(__VA_ARGS__))

/**
 * Executes one or more expressions (which may have a void type, such as a call
 * to a function that returns no value) and always returns true.
 *
 * This is mostly useful for macro metaprogramming.
 */
#define exprify(...) \
    ((__VA_ARGS__), true)

/**
 * If COND is true, the following one or more expressions (which may have a void
 * type) are evaluated and the given block entered like a regular 'if'
 * statement. Can also be used immediately after an 'else' for else-if behavior.
 *
 * This is mostly useful for macro metaprogramming.
 */
#define if_then(COND, ...) \
    if ((COND) && exprify(__VA_ARGS__))

/**
 * Allows you to define or initialize a variable for use with a given block of
 * code. 'break' and 'continue' will both exit the with statement.
 *
 * Some examples:
 *
 *  with (int val = 5) do
 *      printf("%i", val);
 *  while (--val > 0);
 *
 *  with (char ch = fgetc(stdin)) {
 *      if (ch == 'a')
 *          puts("User typed A");
 *      else if (isspace(ch))
 *          puts("User typed whitespace");
 *      else
 *          puts("Don't know what the user typed");
 *  }
 *
 *  // this is technically valid, though not exactly recommended usage
 *  with (int i = 42)
 *      with (double dbl = 3.14)
 *          with (const char *str = "hello world")
 *              printf("%i %f %s\n", i, dbl, str);
 */
#define with(EXPR) \
    for (bool with_block_done_ = false; !with_block_done_; with_block_done_ \
        = true)                                                             \
        for (EXPR; !with_block_done_; with_block_done_ = true)

#endif
