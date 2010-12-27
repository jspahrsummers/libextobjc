/**
 * Macros for metaprogramming
 * ExtendedC
 *
 * Unless otherwise specified for a given block macro, statements can appear
 * immediately after such macros and work as expected. Braces are optional for
 * single statements, just like built-in constructs.
 *
 * by Justin Spahr-Summers
 *
 * Released 9. Nov 2010 into the public domain.
 */

#ifndef EXTC_METAMACROS_H
#define EXTC_METAMACROS_H

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

/**
 * Executes one or more expressions (which may have a void type, such as a call
 * to a function that returns no value) and always returns true.
 */
#define metamacro_exprify(...) \
    ((__VA_ARGS__), true)

/**
 * If COND is true, the following one or more expressions (which may have a void
 * type) are evaluated and the given block entered like a regular 'if'
 * statement. Can also be used immediately after an 'else' for else-if behavior.
 */
#define metamacro_if_then(COND, ...) \
    if ((COND) && metamacro_exprify(__VA_ARGS__))

/**
 * Returns a string representation of VALUE after full macro expansion.
 */
#define metamacro_stringify(VALUE) \
        metamacro_stringify_(VALUE)

/**
 * Returns A and B concatenated after full macro expansion.
 */
#define metamacro_concat(A, B) \
        metamacro_concat_(A, B)

// IMPLEMENTATION DETAILS FOLLOW!
// Do not write code that depends on anything below this line.
#define metamacro_stringify_(VALUE) # VALUE
#define metamacro_concat_(A, B) A ## B

#endif
