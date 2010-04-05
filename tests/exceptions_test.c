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
        exception_test_nested();
    } catch (TestException, ex) {
        ++caught;
            
        try {
            raise(Exception, NULL);
        } catch (Exception, ex) {
            ++caught;
        }
    } finally {
        assert(caught == 2);
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
    } catch (TestException, ex) {
        caught = true;
        throw;
    } finally {
        assert(caught);
    }
}
