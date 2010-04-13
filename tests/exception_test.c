/**
 * libextc exception testcase
 * ExtendedC
 *
 * by Justin Spahr-Summers
 * Copyright (C) 2010
 */

#include <assert.h>
#include "exception_test.h"

static void exception_test_nested (void);
static void exception_test_nested2 (void);

exception_subclass(Exception, TestException);

void exception_test (void) {
    int caught = 0;
    bool executed_finally = false;
    
    // try blocks without anything else are legal
    try {
        assert(caught == 0);
    }
    
    // test nested exception handling in the same function
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

    // exception_test_nested() rethrows a TestException as an Exception
    // this catches it as a TestException again
    try {
        exception_test_nested();
    } catch (TestException, ex) {
        caught = 5;
        
        // throw an exception to increment 'caught'
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
    
    // try and finally blocks without catch blocks are legal and should work
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
    
    // exception_test_nested2() throws a TestException
    // this catches it as an Exception (its superclass) and rethrows it
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

    // throws, catches, then rethrows a TestException
    try {
        raise(TestException, NULL);
    } catch_all (ex) {
        caught = true;
        throw;
    } finally {
        assert(caught);
    }
}
