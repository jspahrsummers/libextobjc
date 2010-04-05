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

/**
 * Represents an exception.
 * Do not manually create objects of this type.
 */
typedef struct exception_ {
    const struct exception_ *backtrace_;
    
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
    if ((ex_propagation_.line = __LINE__, exception_uncaught_ = true,   \
        ex_propagation_.propagate = true))                              \
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
 */
#define try \
    struct exception_data_ *exception_current_data_ = exception_block_push_();  \
    struct exception_propagation_ ex_propagation_ = { .propagate = false };     \
    volatile int exception_unhandled_ = setjmp(exception_current_data_->        \
        context);                                                               \
                                                                                \
    for (volatile bool exception_uncaught_ = true, finalizer_run_ = false,      \
        loop2_done_; (loop2_done_ = false, !finalizer_run_); finalizer_run_ &&  \
        ((exception_uncaught_ &&                                                \
        ((ex_propagation_.propagate && (exception_raise_(                       \
        &exception_current_data_->exception_obj, exception_current_data_->      \
        exception_obj.type, exception_current_data_->exception_obj.data,        \
        __func__, __FILE__, ex_propagation_.line), 1)) ||                       \
        (exception_raise_up_block_(exception_current_data_), 1))) ||            \
        (extc_free(exception_current_data_), 1)))                               \
        switch (exception_unhandled_)                                           \
            for (; !loop2_done_; loop2_done_ = true)                            \
                default:                                                        \
                    if (exception_unhandled_ == 2) {                            \
                        finalizer_run_ = true;                                  \
                        break;                                                  \
                    } else if (exception_unhandled_ == 0)

/**
 * Begins a block of code that is only executed if an exception of class TYPE
 * (or one of its subclasses) is thrown. VAR is the name of a variable that will
 * be defined to hold the exception.
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
                    else if (exception_is_a(&exception_current_data_->          \
                        exception_obj, TYPE) && (exception_uncaught_ = false,   \
                        exception_block_pop_(), exception_unhandled_ = 2))      \
                        for (bool oneLoop_ = false; !oneLoop_; oneLoop_ = true) \
                            for (const exception *VAR =                         \
                                &exception_current_data_->exception_obj;        \
                                !oneLoop_; oneLoop_ = true)

/**
 * Begins a block of code that catches any and all exceptions. VAR is the name
 * of a variable that will be defined to hold the exception.
 *
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
                    else if ((exception_uncaught_ = false,                      \
                        exception_block_pop_(), exception_unhandled_ = 2))      \
                        for (bool oneLoop_ = false; !oneLoop_; oneLoop_ = true) \
                            for (const exception *VAR =                         \
                                &exception_current_data_->exception_obj;        \
                                !oneLoop_; oneLoop_ = true)

/**
 * Begins a block of code that is executed regardless of any exceptions.
 * This must appear after any try, catch, or catch_all blocks, and is always
 * executed after said blocks.
 *
 * Some notes for usage:
 *      - 'break' is legal within a finally block.
 *      - It is illegal to 'return' or 'goto' out of a finally block.
 *      - This macro uses some pretty extreme sorcery involving, at times,
 *        absurd 'if' statements. To avoid issues, braces should ALWAYS be used
 *        enclosing a finally block and within the block itself.
 */
#define finally \
                    else                                                        \
                        case 2:                                                 \
                            for (; !finalizer_run_; finalizer_run_ = true)      \
                                for (; !finalizer_run_; finalizer_run_ = true)

/**
 * Root class for all exceptions thrown by ExtendedC modules.
 * You are of course free to declare your own separate exception hierarchy.
 */
exception_declaration(Exception);

// memory.h depends on some definitions in here
#include "memory.h"

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

struct exception_propagation_ {
    bool propagate;
    unsigned long line;
};

extern struct exception_data_ *exception_current_block_;

void exception_block_pop_ (void);
struct exception_data_ *exception_block_push_ (void);
void exception_raise_ (const exception *backtrace, const struct exception_type_info *type, const void *data, const char *function, const char *file, unsigned long line);
void exception_raise_up_block_ (struct exception_data_ *currentBlock);
void exception_test (void);

#endif
