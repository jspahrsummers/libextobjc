/**
 * libextc exceptions testcase
 * ExtendedC
 *
 * by Justin Spahr-Summers
 * Copyright (C) 2010
 */

#include <assert.h>
#include "exceptions_test.h"

static void exception_test_nested (void);
static void exception_test_nested2 (void);

exception_subclass(Exception, TestException);

void exceptions_test (void) {
    int caught = 0;
    bool executed_finally = false;
    
    try {
        assert(caught == 0);
    }
    
    try {
        try {
            raise(Exception, NULL);
        }
    } catch (Exception, ex) {
        caught = 1;
    } finally {
        assert(caught == 1);
        executed_finally = true;
    }
    
    assert(executed_finally);
    executed_finally = false;

    try {
        exception_test_nested();
    } catch (TestException, ex) {
        caught = 5;
            
        try {
            raise(Exception, NULL);
        } catch (Exception, ex) {
            ++caught;
        }
    } finally {
        assert(caught == 6);
        executed_finally = true;
    }
    
    assert(executed_finally);
    executed_finally = false;
    
    try {
        caught = 10;
    } finally {
        assert(caught == 10);
        executed_finally = true;
    }
    
    assert(executed_finally);
}

static void exception_test_nested (void) {
    bool caught = false;
    
    try {
        exception_test_nested2();
    } catch (Exception, ex) {
        caught = true;
        throw;
    } finally {
        assert(caught);
    }
}

static void exception_test_nested2 (void) {
    bool caught = false;

    try {
        raise(TestException, NULL);
    } catch_all (ex) {
        caught = true;
        throw;
    } finally {
        assert(caught);
    }
}
