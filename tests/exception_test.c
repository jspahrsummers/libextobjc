/**
 * libextc exception testcase
 * ExtendedC
 *
 * by Justin Spahr-Summers
 * Copyright (C) 2010
 */

#include "exception_test.h"

static void exception_test_nested (void);
static void exception_test_nested2 (void);

exception_subclass(Exception, TestException);

void exception_test (void) {
    int caught = 0;
    bool executed_finally = false;
    
    // try blocks without anything else are legal
    try {
        LOG_TEST("try block without any catches or finally block");
        assert(caught == 0);
    }
    
    // test nested exception handling in the same function
    try {
        try {
            LOG_TEST("try block nested within another try block");
            raise(Exception, NULL);
        }
    } catch (Exception, ex) {
        LOG_TEST("catch block catching a nested exception");
        caught = 1;
    } finally {
        LOG_TEST("finally block after an exception");
        
        assert(caught == 1);
        executed_finally = true;
    }
    
    assert(executed_finally);
    executed_finally = false;

    // exception_test_nested() rethrows a TestException as an Exception
    // this catches it as a TestException again
    try {
        LOG_TEST("calling function to rethrow a TestException as an Exception");
        exception_test_nested();
    } catch (TestException, ex) {
        LOG_TEST("catching rethrown Exception as its true type as a TestException");
        caught = 5;
        
        // throw an exception to increment 'caught'
        try {
            LOG_TEST("try block nested within a catch block");
            raise(Exception, NULL);
        } catch (Exception, ex) {
            LOG_TEST("catch block nested within a catch block");
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
        LOG_TEST("try block without any catches");
        caught = 10;
    } finally {
        LOG_TEST("finally block without any catches");
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
        LOG_TEST("calling function to throw a TestException");
        exception_test_nested2();
    } catch (Exception, ex) {
        LOG_TEST("catching a TestException as an Exception and rethrowing");
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
        LOG_TEST("throwing a TestException (subclass of Exception)");
        raise(TestException, NULL);
    } catch_all (ex) {
        LOG_TEST("catching and rethrowing our thrown exception (of any type)");
        caught = true;
        throw;
    } finally {
        assert(caught);
    }
}
