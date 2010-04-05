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
    volatile int caught = 0;

    try {
        exception_test_nested();
    } catch (TestException, ex) {
        try {
            ++caught;
            raise(Exception, NULL);
        } catch (Exception, ex) {
            ++caught;
        }
    } finally {
        assert(caught == 2);
    }
}

static void exception_test_nested (void) {
    volatile bool caught = false;
    
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
    volatile bool caught = false;

    try {
        raise(TestException, NULL);
    } catch (TestException, ex) {
        caught = true;
        throw;
    } finally {
        assert(caught);
    }
}
