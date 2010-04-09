/**
 * Exception handling
 * ExtendedC
 *
 * by Justin Spahr-Summers
 * Copyright (C) 2010
 */

#ifndef EXTC_EXCEPTIONS_H
#define EXTC_EXCEPTIONS_H

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include <setjmp.h>
#include <stdbool.h>
#include <stddef.h>
#include "blocks.h"

struct exception_data_;

/**
 * Represents an exception.
 * Do not manually create objects of this type.
 */
typedef struct exception_ {
    struct exception_data_ *backtrace_;
    
    /**
     * This exception's type.
     */
    const struct exception_type_info *type;
    
    /**
     * The name of the function from which this exception was thrown.
     */
    const char *function;
    
    /**
     * The name of the source file from which this exception was thrown.
     */
    const char *file;
    
    /**
     * The line number in the source file from which this exception was thrown.
     */
    unsigned long line;
    
    /**
     * Custom data provided by the code that threw the exception.
     */
    const void *data;
} exception;

/**
 * Represents a class of exceptions.
 * Do not manually create objects of this type.
 */
struct exception_type_info {
    /**
     * Exception class to inherit from, if any.
     */
    const struct exception_type_info * const superclass;
    
    /**
     * Name of the exception class.
     */
    const char * const name;
};
    
/**
 * Defines an exception class TYPE that is not a subclass of any other.
 * This should never be invoked more than once (even through file inclusion).
 */
#define exception_class(TYPE) \
        exception_type_definition_(NULL, TYPE)

/**
 * Declares (but does not define) an exception class named TYPE.
 * Intended to be used in public interfaces.
 */
#define exception_declaration(TYPE) \
    extern const struct exception_type_info TYPE ## _; \
    extern const struct exception_type_info * const TYPE

/**
 * Determines if 'ex' belongs to exception class 'type' or a subclass of 'type'.
 */
bool exception_is_a (const exception *ex, const struct exception_type_info *type);

/**
 * Defines an exception class TYPE that is a subclass of PARENT.
 * This should never be invoked more than once (even through file inclusion).
 */
#define exception_subclass(PARENT, TYPE) \
        exception_type_definition_(& PARENT ## _, TYPE)

/**
 * Raises a new exception of class TYPE.
 * DATA, a pointer, can be used to pass custom data to any recovery code.
 */
#define raise(TYPE, DATA) \
    exception_raise_(NULL, TYPE, DATA, __func__, __FILE__, __LINE__)

/**
 * Rethrows the current exception to be taken care of further up the stack.
 * This can only be called from within a catch block.
 */
#define throw \
    if (exprify(exception_propagate_line_ = __LINE__,   \
        exception_uncaught_ = true))                    \
        break

/**
 * Begins a block of code that may cause exceptions.
 * This must appear before any catch, catch_all, or finally blocks.
 *
 * Some notes for usage:
 *      - 'break' is legal within a try block. Any finally block will still be
 *        executed.
 *      - It is illegal to 'return' or 'goto' out of a try block.
 *      - This macro uses some pretty extreme sorcery involving, at times,
 *        absurd 'if' statements. To avoid issues, braces should ALWAYS be used
 *        enclosing a try block and within the block itself.
 *      - Any variables with automatic storage duration (i.e., defined in
 *        function scope) that are modified INSIDE the try block and NOT
 *        qualified 'volatile' are indeterminate if an exception is caught. This
 *        is a restriction imposed by setjmp() and longjmp(). The easy solution
 *        is to use 'volatile' with any such variables.
 */
#define try \
    /* the next few loops initialize variables without naming conflicts */  \
    for (volatile bool loop_done_ = false; !loop_done_; loop_done_ = true)  \
    for (struct exception_data_ *exception_current_data_ =                  \
        exception_block_push_(); !loop_done_; loop_done_ = true)            \
    for (volatile unsigned long exception_propagate_line_ = __LINE__;       \
        !loop_done_; loop_done_ = true)                                     \
                                                                            \
    /* exception_unhandled_ takes on a few different meanings:              \
        0 = no exceptions thrown yet, execute 'try' block                   \
        1 = exception thrown, find a suitable 'catch' block                 \
        2 = handling finished, execute 'finally' block */                   \
                                                                            \
    for (int exception_unhandled_ = setjmp(exception_current_data_->        \
        context); !loop_done_; loop_done_ = true)                           \
    for (volatile bool exception_uncaught_ = (exception_unhandled_ == 1),   \
        finalizer_run_ = false; !finalizer_run_;                            \
        /* if the 'finally' block has been executed... */                   \
        (finalizer_run_ && (                                                \
            /* if an exception wasn't fully handled... */                   \
            (exception_uncaught_ &&                                         \
                /* push to a handler further up, saving a backtrace */      \
                exprify(exception_rethrow_from_(exception_current_data_,    \
                        &exception_current_data_->exception_obj,            \
                        exception_propagate_line_))                         \
            ) ||                                                            \
            /* ... or the exception WAS handled cleanly... */               \
            exprify(exception_block_free_(exception_current_data_))         \
        )) ||                                                               \
        /* ... or if there were no exceptions thrown... */                  \
        (exception_unhandled_ == 0 &&                                       \
            /* go back in and execute the 'finally' block */                \
            exprify(exception_block_pop_(), exception_unhandled_ = 2)       \
        ))                                                                  \
                                                                            \
        /* this Duff's device ripoff allows us to circumvent syntax */      \
        /* see the 'finally' macro to really understand why */              \
        switch (exception_unhandled_)                                       \
            /* creates a new scope, no braces necessary */                  \
            for (bool loop2_done_ = false; !loop2_done_; loop2_done_ =      \
                true)                                                       \
                /* jumps here if exception_unhandled_ is 0 or 1 OR there    \
                   is no finally block further down */                      \
                default:                                                    \
                    if (exception_unhandled_ == 2) {                        \
                        /* no finally block, so just say we're done */      \
                        finalizer_run_ = true;                              \
                        break;                                              \
                    } else if (exception_unhandled_ == 0)                   \
                        /* try block begins with user code */

/**
 * Begins a block of code that is only executed if an exception of class TYPE
 * (or one of its subclasses) is thrown. VAR is the name of a variable that will
 * be defined to hold the exception.
 *
 * This must appear immediately after a try or catch block.
 *
 * If an exception is caught by this block, no following catch blocks will be
 * executed.
 *
 * Some notes for usage:
 *      - 'break' is legal within a catch block. Any finally block will still be
 *        executed.
 *      - It is illegal to 'return' or 'goto' out of a catch block.
 *      - This macro uses some pretty extreme sorcery involving, at times,
 *        absurd 'if' statements. To avoid issues, braces should ALWAYS be used
 *        enclosing a catch block and within the block itself.
 */
#define catch(TYPE, VAR) \
                    /* if the exception type matches, mark it as caught */  \
                    else if_then (exception_is_a(&exception_current_data_-> \
                        exception_obj, TYPE), exception_uncaught_ = false,  \
                        exception_block_pop_(), exception_unhandled_ = 2)   \
                        with (const exception *VAR =                        \
                            &exception_current_data_->exception_obj)        \
                            /* catch block begins with user code */

/**
 * Begins a block of code that catches any and all exceptions. VAR is the name
 * of a variable that will be defined to hold the exception.
 *
 * This must appear immediately after a try or catch block.
 * No following catch blocks will be executed.
 *
 * Some notes for usage:
 *      - 'break' is legal within a catch_all block. Any finally block will
 *        still be executed.
 *      - It is illegal to 'return' or 'goto' out of a catch_all block.
 *      - This macro uses some pretty extreme sorcery involving, at times,
 *        absurd 'if' statements. To avoid issues, braces should ALWAYS be used
 *        enclosing a catch_all block and within the block itself.
 */
#define catch_all(VAR) \
                    /* mark the exception as caught */                      \
                    else if ((exception_uncaught_ = false,                  \
                        exception_block_pop_(), exception_unhandled_ = 2))  \
                        with (const exception *VAR =                        \
                            &exception_current_data_->exception_obj)        \
                            /* catch_all block begins with user code */

/**
 * Begins a block of code that is executed regardless of any exceptions.
 * This must appear immediately after any try, catch, or catch_all blocks, and
 * is always executed after said blocks.
 *
 * Some notes for usage:
 *      - 'break' is legal within a finally block.
 *      - It is illegal to 'return' or 'goto' out of a finally block.
 *      - This macro uses some pretty extreme sorcery involving, at times,
 *        absurd 'if' statements. To avoid issues, braces should ALWAYS be used
 *        enclosing a finally block and within the block itself.
 */
#define finally \
                    /* this part right here is just amazing...                  \
                       one of the conditions above will ALWAYS match, so the    \
                       'else' means that this code is basically ignored... */   \
                    else                                                        \
                        /* UNLESS exception_unhandled_ was 2 at the start, in   \
                           which case the switch() jumps in here */             \
                        case 2:                                                 \
                            /* meaningless loop to allow the use of 'break' */  \
                            for (; !finalizer_run_; finalizer_run_ = true)      \
                                for (; !finalizer_run_; finalizer_run_ = true)  \
                                    /* finally block begins with user code */

/**
 * Root class for all exceptions thrown by ExtendedC modules.
 * You are of course free to declare your own separate exception hierarchy.
 */
exception_declaration(Exception);

// IMPLEMENTATION DETAILS FOLLOW!
// Do not write code that depends on anything below this line.
#define exception_type_definition_(PARENT, TYPE) \
    const struct exception_type_info TYPE ## _ =                    \
        { .superclass = PARENT, .name = # TYPE };                   \
    const struct exception_type_info * const TYPE = &( TYPE ## _ )

struct exception_data_ {
    struct exception_data_ *parent;
    jmp_buf context;
    exception exception_obj;
};

extern struct exception_data_ *exception_current_block_;

void exception_block_free_ (struct exception_data_ *block);
void exception_block_pop_ (void);
struct exception_data_ *exception_block_push_ (void);
void exception_raise_ (struct exception_data_ *backtrace, const struct exception_type_info *type, const void *data, const char *function, const char *file, unsigned long line);
void exception_raise_up_block_ (struct exception_data_ *currentBlock);
#define exception_rethrow_from_(BLOCK, EX, LINE) \
    exception_raise_((BLOCK), (EX)->type, (EX)->data, __func__, __FILE__, (LINE))
void exception_test (void);

#endif
