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

/**
 * Returns the number of arguments (up to nine) provided to the macro.
 *
 * Inspired by P99: http://p99.gforge.inria.fr
 */
#define metamacro_argcount(...) \
        metamacro_index9_(__VA_ARGS__, 9, 8, 7, 6, 5, 4, 3, 2, 1)

/**
 * For each consecutive variable argument (up to nine), MACRO is passed the
 * zero-based index of the current argument and the argument itself.
 *
 * Inspired by P99: http://p99.gforge.inria.fr
 */
#define metamacro_foreach(MACRO, ...) \
        metamacro_concat(metamacro_for, metamacro_argcount(__VA_ARGS__))(MACRO, __VA_ARGS__)

/**
 * Identical to #metamacro_foreach, but accepts an additional context argument,
 * which will be passed through to MACRO after the index argument.
 */
#define metamacro_foreach_cxt(MACRO, CONTEXT, ...) \
        metamacro_concat(metamacro_for_cxt, metamacro_argcount(__VA_ARGS__))(MACRO, CONTEXT, __VA_ARGS__)

/**
 * Returns the first argument given.
 *
 * This is useful when implementing a variadic macro, where you may have only
 * one variadic argument, but no way to retrieve it (for example, because \c ...
 * always needs to match at least one thing).
 *
 * @code

#define varmacro(...) \
    metamacro_first(__VA_ARGS__, 0)

 * @endcode
 */
#define metamacro_first(FIRST, ...) FIRST

// IMPLEMENTATION DETAILS FOLLOW!
// Do not write code that depends on anything below this line.
#define metamacro_stringify_(VALUE) # VALUE
#define metamacro_concat_(A, B) A ## B
#define metamacro_index9_(_0, _1, _2, _3, _4, _5, _6, _7, _8, _9, ...) _9

#define metamacro_for1(MACRO, _0)                                                                                                   MACRO(0, _0)
#define metamacro_for2(MACRO, _0, _1)                                   metamacro_for1(MACRO, _0)                                   MACRO(1, _1)
#define metamacro_for3(MACRO, _0, _1, _2)                               metamacro_for2(MACRO, _0, _1)                               MACRO(2, _2)
#define metamacro_for4(MACRO, _0, _1, _2, _3)                           metamacro_for3(MACRO, _0, _1, _2)                           MACRO(3, _3)
#define metamacro_for5(MACRO, _0, _1, _2, _3, _4)                       metamacro_for4(MACRO, _0, _1, _2, _3)                       MACRO(4, _4)
#define metamacro_for6(MACRO, _0, _1, _2, _3, _4, _5)                   metamacro_for5(MACRO, _0, _1, _2, _3, _4)                   MACRO(5, _5)
#define metamacro_for7(MACRO, _0, _1, _2, _3, _4, _5, _6)               metamacro_for6(MACRO, _0, _1, _2, _3, _4, _5)               MACRO(6, _6)
#define metamacro_for8(MACRO, _0, _1, _2, _3, _4, _5, _6, _7)           metamacro_for7(MACRO, _0, _1, _2, _3, _4, _5, _6)           MACRO(7, _7)
#define metamacro_for9(MACRO, _0, _1, _2, _3, _4, _5, _6, _7, _8)       metamacro_for8(MACRO, _0, _1, _2, _3, _4, _5, _6, _7)       MACRO(8, _8)
#define metamacro_for10(MACRO, _0, _1, _2, _3, _4, _5, _6, _7, _8, _9)  metamacro_for9(MACRO, _0, _1, _2, _3, _4, _5, _6, _7, _8)   MACRO(9, _9)

#define metamacro_for_cxt1(MACRO, CONTEXT, _0) MACRO(0, CONTEXT, _0)
#define metamacro_for_cxt2(MACRO, CONTEXT, _0, _1) metamacro_for_cxt1(MACRO, CONTEXT, _0) MACRO(1, CONTEXT, _1)
#define metamacro_for_cxt3(MACRO, CONTEXT, _0, _1, _2) metamacro_for_cxt2(MACRO, CONTEXT, _0, _1) MACRO(2, CONTEXT, _2)
#define metamacro_for_cxt4(MACRO, CONTEXT, _0, _1, _2, _3) metamacro_for_cxt3(MACRO, CONTEXT, _0, _1, _2) MACRO(3, CONTEXT, _3)
#define metamacro_for_cxt5(MACRO, CONTEXT, _0, _1, _2, _3, _4) metamacro_for_cxt4(MACRO, CONTEXT, _0, _1, _2, _3) MACRO(4, CONTEXT, _4)
#define metamacro_for_cxt6(MACRO, CONTEXT, _0, _1, _2, _3, _4, _5) metamacro_for_cxt5(MACRO, CONTEXT, _0, _1, _2, _3, _4) MACRO(5, CONTEXT, _5)
#define metamacro_for_cxt7(MACRO, CONTEXT, _0, _1, _2, _3, _4, _5, _6) metamacro_for_cxt6(MACRO, CONTEXT, _0, _1, _2, _3, _4, _5) MACRO(6, CONTEXT, _6)
#define metamacro_for_cxt8(MACRO, CONTEXT, _0, _1, _2, _3, _4, _5, _6, _7) metamacro_for_cxt7(MACRO, CONTEXT, _0, _1, _2, _3, _4, _5, _6) MACRO(7, CONTEXT, _7)
#define metamacro_for_cxt9(MACRO, CONTEXT, _0, _1, _2, _3, _4, _5, _6, _7, _8) metamacro_for_cxt8(MACRO, CONTEXT, _0, _1, _2, _3, _4, _5, _6, _7) MACRO(8, CONTEXT, _8)
#define metamacro_for_cxt10(MACRO, CONTEXT, _0, _1, _2, _3, _4, _5, _6, _7, _8, _9) metamacro_for_cxt9(MACRO, CONTEXT, _0, _1, _2, _3, _4, _5, _6, _7, _8) MACRO(9, CONTEXT, _9)

#endif
