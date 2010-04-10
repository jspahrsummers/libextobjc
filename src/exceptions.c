/**
 * Exception handling
 * ExtendedC
 *
 * by Justin Spahr-Summers
 * Copyright (C) 2010
 */

#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include "exceptions.h"
#include "memory.h"

/*** Exception types ***/
exception_class(Exception);

/*** Global data ***/
struct exception_data_ *exception_current_block_;

/*** Private functions ***/
static
void exception_print_trace (const exception *ex);

void exception_block_free_ (struct exception_data_ *block) {
    if (block->exception_obj.backtrace_) {
        exception_block_free_(block->exception_obj.backtrace_);
        
        #ifdef DEBUG
        block->exception_obj.backtrace_ = NULL;
        #endif
    }
    
    extc_free(block);
}

void exception_block_pop_ (void) {
    assert(exception_current_block_ != NULL);
    exception_current_block_ = exception_current_block_->parent;
}

struct exception_data_ *exception_block_push_ (void) {
    struct exception_data_ *ret = extc_malloc(sizeof(*ret));
    
    ret->parent = exception_current_block_;
    ret->exception_obj.backtrace_ = NULL;
    return exception_current_block_ = ret;
}

bool exception_is_a (const exception *ex, const struct exception_type_info *type) {
    const struct exception_type_info *currentType = ex->type;
    
    while (currentType) {
        if (currentType == type)
            return true;
        
        currentType = currentType->superclass;
    }
    
    return false;
}

static
void exception_print_trace (const exception *ex) {
    assert(ex != NULL);
    
    fprintf(stderr, "*** Uncaught %s raised in function %s() at %s:%lu\n", ex->type->name, ex->function, ex->file, ex->line);
    while (ex->backtrace_) {
        ex = &ex->backtrace_->exception_obj;
        fprintf(stderr, "*** Previously raised in function %s() at %s:%lu\n", ex->function, ex->file, ex->line);
    }
}

void exception_raise_ (struct exception_data_ *backtrace, const struct exception_type_info *type, const void *data, const char *function, const char *file, unsigned long line) {
    struct exception_data_ *currentBlock = exception_current_block_;
    
    if (currentBlock) {
        currentBlock->exception_obj.backtrace_ = backtrace  ;
        currentBlock->exception_obj.type       = type       ;
        currentBlock->exception_obj.function   = function   ;
        currentBlock->exception_obj.file       = file       ;
        currentBlock->exception_obj.line       = line       ;
        currentBlock->exception_obj.data       = data       ;
        longjmp(currentBlock->context, 1);
    }
    
    exception_print_trace(&(const exception){
        .backtrace_ = backtrace,
        .type       = type,
        .function   = function,
        .file       = file,
        .line       = line
    });
    
    exit(EXIT_FAILURE);
}

void exception_raise_up_block_ (struct exception_data_ *currentBlock) {
    exception exception_copy = currentBlock->exception_obj;
    
    // don't use block_free_() because we need the backtrace
    extc_free(currentBlock);
    
    if (exception_current_block_) {
        exception_current_block_->exception_obj = exception_copy;
        longjmp(exception_current_block_->context, 1);
    }
    
    exception_print_trace(&exception_copy);
    exit(EXIT_FAILURE);
}
