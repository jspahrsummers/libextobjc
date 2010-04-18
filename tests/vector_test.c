/**
 * libextc vector testcase
 * ExtendedC
 *
 * by Justin Spahr-Summers
 * Copyright (C) 2010
 */

#include "exception.h"
#include "vector_test.h"

void vector_test (void) {
    // generic vector structure!
    // tests a bunch of different operations which are mostly self-explanatory
    
    vector(int) *v = vector_new(int);
    vector(double) *vf = vector_new(double);
    vector(const char *) *vs = vector_new(const char *);
    
    assert(v != NULL);
    assert(vf != NULL);
    assert(vs != NULL);
    
    LOG_TEST("allocated three vectors: %p, %p, %p", (void *)v, (void *)vf, (void *)vs);
    
    LOG_TEST("adding items to vector");
    vector_add(v, 10);
    vector_add(v, 1337);
    vector_add(vs, "foobar");
    
    LOG_TEST("inserting item in vector");
    vector_insert(v, 55, 1);
    
    // constructs a couple arrays on-the-fly and adds them
    LOG_TEST("adding array to vector");
    vector_add_array(vf, 3, ((const double[]){ 6.7, 3.14, 365.25 }));
    
    LOG_TEST("inserting array in vector");
    vector_insert_array(vs, 2, ((const char *[]){ "hello", "world" }), 0);
    
    LOG_TEST("validating contents of vectors with foreach_index");
    vector_foreach_index (i, int val, v) {
        assert(i < 3);
    
        // ensures that the items are at the intended indices
        switch (i) {
        case 0:
            assert(val == 10);
            assert(vector_at(vf, i) == 6.7);
            assert(strcmp(vector_at(vs, i), "hello") == 0);
            break;
        
        case 1:
            assert(val == 55);
            assert(vector_at(vf, i) == 3.14);
            assert(strcmp(vector_at(vs, i), "world") == 0);
            break;
        
        case 2:
            assert(val == 1337);
            assert(vector_at(vf, i) == 365.25);
            assert(strcmp(vector_at(vs, i), "foobar") == 0);
            break;
        }
    }
    
    // make sure an attempted access out of bounds throws an exception
    bool out_of_bounds = false;
    volatile int i = 0;
    try {
        LOG_TEST("attempting out-of-bounds access");
        i = vector_at(v, 10);
    } catch (IndexOutOfBoundsException, ex) {
        LOG_TEST("caught IndexOutOfBoundsException");
        out_of_bounds = true;
    } finally {
        assert(out_of_bounds);
        assert(i == 0);
    }
    
    LOG_TEST("removing a range from vector");
    vector_remove_range(vf, 1, 2);
    assert(vf->count == 1);
    
    LOG_TEST("removing items from vector");
    vector_remove(vs, 2);
    vector_remove(vs, 0);
    assert(vs->count == 1);
    
    vector_remove(vs, 0);
    assert(vs->count == 0);
    
    LOG_TEST("deleting vectors %p, %p", (void *)vf, (void *)vs);
    vector_delete(vf);
    vector_delete(vs);
    
    vector(vector(int) *) *vv = vector_new(vector(int) *);
    LOG_TEST("created vector-of-vectors %p", (void *)vv);
    
    vector(int) *subv = vector_new(int);
    
    vector_add(subv, 2);
    vector_add(subv, 3);
    vector_add(subv, 5);
    vector_add(subv, 8);
    
    // these lines produce warnings because GCC can't tell that the vector() structures are the same
    // i've verified that the assignments conform to C99 down to the letter
    LOG_TEST("adding vector objects to vector-of-vectors");
    vector_add(vv, v);
    vector_add(vv, subv);
    
    // ditto with this loop
    LOG_TEST("validating the contents of nested vectors with foreach");
    vector_foreach (vector(int) *loopv, vv) {
        assert(loopv == v || loopv == subv);
        assert(loopv != NULL);
    
        vector_foreach (int value, loopv) {
            if (loopv == v) {
                assert(value == 10 || value == 55 || value == 1337);
            } else {
                assert(value == 2 || value == 3 || value == 5 || value == 8);
            }
        }
        
        LOG_TEST("deleting nested vector %p", (void *)loopv);
        vector_delete(loopv);
    }
    
    vector_delete(vv);
}
