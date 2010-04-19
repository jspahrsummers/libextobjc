/**
 * libextc scope testcase
 * ExtendedC
 *
 * by Justin Spahr-Summers
 * Copyright (C) 2010
 */

#include "scope_test.h"

static
void scope_alloc (void);

void scope_test (void) {
    scope_alloc();
}

void scope_alloc (void) {
    LOG_TEST("using scope() to automatically deallocate memory");

    void *ptr = NULL;
    bool cleaned_up = false;
    
    // destructor-like functionality!
    // similar to the scope() constructs in the D programming language
    
    scope(new) {
        ptr = malloc(256);
        assert(ptr != NULL);
        LOG_TEST("allocated pointer %p", (void *)ptr);
        
        // frees the just-allocated memory *when this scope exits*
        scope(exit) {
            LOG_TEST("inside scope cleanup, freeing pointer %p", (void *)ptr);
            free(ptr);
            ptr = NULL;
        }
        
        scope(exit) {
            LOG_TEST("inside second scope cleanup");
            cleaned_up = true;
            
            // previous cleanup block should've been executed already
            assert(ptr == NULL);
        }
        
        // 'ptr' has not been freed yet!
        assert(ptr != NULL);
        cleaned_up = false;
        
        LOG_TEST("about to leave scope");
    }
    
    // 'ptr' has now been freed!
    assert(cleaned_up);
    assert(ptr == NULL);
    LOG_TEST("scope has been cleaned up");
}

static
void scope_benchmark1 (void);

static
void scope_benchmark2 (void);

static
void scope_benchmark3 (void);

static
void scope_benchmark4 (void);

static
void scope_benchmark5 (void);

void scope_benchmark (void) {
    scope_benchmark1();
    scope_benchmark2();
    scope_benchmark4();
    scope_benchmark3();
    scope_benchmark5();
}

static
void scope_benchmark1 (void) {
    BENCHMARK(scope(new) {});
}

static
void scope_benchmark2 (void) {
    BENCHMARK(
        scope(new) {
            scope(exit) {}
        }
    );
}

static
void scope_benchmark4 (void) {
    unsigned i = 0;
    benchmark_t start;
    double elapsed;

    benchmark_begin(&start);
    // compare with scope_benchmark3() and scope_benchmark5()
    for (;i < DEFAULT_BENCHMARK_TIMES / 10;++i) {
        scope(new) {
            scope(exit) {}
            scope(exit) {}
            scope(exit) {}
            scope(exit) {}
            scope(exit) {}
        }
    }
    
    elapsed = benchmark_end(&start) * 1000;
    LOG_BENCHMARK("five successive scope(exit) statements", DEFAULT_BENCHMARK_TIMES / 10, elapsed);
}

static
void scope_benchmark3 (void) {
    unsigned i = 0;
    benchmark_t start;
    double elapsed;

    benchmark_begin(&start);
    // tests scope cleanup over a long function
    for (;i < DEFAULT_BENCHMARK_TIMES / 10;++i) {
        scope(new) {
            scope(exit) {}
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            scope(exit) {}
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            scope(exit) {}
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            scope(exit) {}
            
            
            
            
            
            
            
            
            
            
            
            
            scope(exit) {}
        }
    }
    
    elapsed = benchmark_end(&start) * 1000;
    LOG_BENCHMARK("five scope(exit) statements spread out over a function", DEFAULT_BENCHMARK_TIMES / 10, elapsed);
}

static
void scope_benchmark5 (void) {
    unsigned i = 0;
    benchmark_t start;
    double elapsed;

    benchmark_begin(&start);
    // tests scope cleanup over a long function
    for (;i < DEFAULT_BENCHMARK_TIMES / 10;++i) {
        scope(new) {
            scope(exit) {}
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            scope(exit) {}
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            scope(exit) {}
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            scope(exit) {}
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            scope(exit) {}
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
        }
    }
    
    elapsed = benchmark_end(&start) * 1000;
    LOG_BENCHMARK("five scope(exit) statements spread out over a long function", DEFAULT_BENCHMARK_TIMES / 10, elapsed);
}
