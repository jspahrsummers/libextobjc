//
//  EXTCoroutine.h
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-05-22.
//  Copyright (C) 2012 Justin Spahr-Summers.
//  Released under the MIT license.
//

/**
 * Defines a coroutine, which is a generalized version of a subroutine that
 * supports multiple entry and exit points. This macro takes as its arguments
 * the parameter declarations for the coroutine, which will be visible within
 * its definition.
 *
 * The syntax for using this macro is a bit odd. After the argument list
 * consisting of the coroutine's parameters, you must pass another argument list
 * that consists exclusively of a statement to be used as the coroutine's body.
 *
 * For example, this defines a coroutine which takes an integer and double
 * argument and yields (returns) twice:
 *
 * @code

double (^myCoroutine)(int, double) = coroutine(int n, double x)({
    yield n / x;
    yield n * 2 / x;
});

double x = myCoroutine(42, 1.5);
double y = myCoroutine(42, 2.0);
 
 * @endcode
 *
 * @note In typical usage, the arguments to a coroutine would not change until
 * the coroutine has been exhausted (as in the case of a reader or parser);
 * however, it is completely legal to do so, and your coroutine code should be
 * prepared for such a case.
 *
 * @note Coroutines are implemented using blocks. Consequently, to store data
 * above and beyond the execution state of the coroutine, you can use variables
 * qualified \c __block in the enclosing scope. Variables without the \c __block
 * qualifier will be lost (perhaps even indeterminate) between invocations of
 * the coroutine.
 *
 * @warning Coroutines are not thread-safe. Because coroutines inherently
 * contain some execution state, executing the same coroutine on multiple
 * threads is considered undefined behavior. It is, however, legal to
 * synchronize a coroutine to ensure that it only executes on a single thread at
 * any given time.
 */
#define coroutine(...) \
    ^{ \
        __block unsigned long ext_coroutine_line_ = 0; \
        \
        return [ \
            ^(__VA_ARGS__) coroutine_body

/**
 * Returns from the coroutine, passing back the given value. If the coroutine's
 * return type is \c void, no value should be given to this macro. If the
 * coroutine is subsequently invoked again, it will resume execution from the
 * point at which \c yield was used.
 *
 * This macro can be used identically to the \c return keyword, with or without
 * parentheses.
 */
#define yield \
    if ((ext_coroutine_line_ = __LINE__) == 0) \
        case __LINE__: \
            ; \
    else \
        return

/*** implementation details follow ***/
#define coroutine_body(STATEMENT) \
            { \
                for (;; ext_coroutine_line_ = 0) \
                    switch (ext_coroutine_line_) \
                        default: \
                            STATEMENT \
            } \
        copy]; \
    }()
