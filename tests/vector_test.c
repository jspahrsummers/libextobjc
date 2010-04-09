/**
 * libextc vector testcase
 * ExtendedC
 *
 * by Justin Spahr-Summers
 * Copyright (C) 2010
 */

#include <assert.h>
#include <stdbool.h>
#include <string.h>
#include "exceptions.h"
#include "vector_test.h"

void vector_test (void) {
    vector(int) *v = vector_new(int);
    vector(double) *vf = vector_new(double);
    vector(const char *) *vs = vector_new(const char *);
    
    vector_add(v, 10);
    vector_add(v, 1337);
    vector_insert(v, 55, 1);
    
    vector_add(vs, "foobar");
    
    vector_add_array(vf, 3, ((const double[]){ 6.7, 3.14, 365.25 }));
    vector_insert_array(vs, 2, ((const char *[]){ "hello", "world" }), 0);
    
    vector_foreach_index (i, int val, v) {
        assert(i < 3);
    
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
    
    bool out_of_bounds = false;
    volatile int i = 0;
    try {
        i = vector_at(v, 10);
    }/* catch (IndexOutOfBoundsException, ex) {
        out_of_bounds = true;
    } finally {
        assert(out_of_bounds);
        assert(i == 0);
    }*/
    
    vector_remove(vf, 1);
    assert(vf->count == 2);
    
    vector_remove(vs, 2);
    vector_remove(vs, 1);
    assert(vs->count == 1);
    
    vector_remove(vs, 0);
    assert(vs->count == 0);
        
    vector_delete(vf);
    vector_delete(vs);
    
    vector(vector(int) *) *vv = vector_new(vector(int) *);
    vector(int) *subv = vector_new(int);
    
    vector_add(subv, 2);
    vector_add(subv, 3);
    vector_add(subv, 5);
    vector_add(subv, 8);
    
    // these lines produce warnings because GCC can't tell that the vector() structures are the same
    // i've verified that the assignments conform to C99 down to the letter
    vector_add(vv, v);
    vector_add(vv, subv);
    
    // ditto with this loop
    vector_foreach (vector(int) *loopv, vv) {
        assert(loopv == v || loopv == subv);
    
        vector_foreach (int value, loopv) {
            if (loopv == v) {
                assert(value == 10 || value == 55 || value == 1337);
            } else {
                assert(value == 2 || value == 3 || value == 5 || value == 8);
            }
        }
        
        vector_delete(loopv);
    }
    
    vector_delete(vv);
}
