/**
 * libextc testcase helper functions
 * ExtendedC
 *
 * by Justin Spahr-Summers
 *
 * Released 9. Nov 2010 into the public domain.
 */

#ifndef EXTC_TEST_TEST_H
#define EXTC_TEST_TEST_H

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include <assert.h>
#include <inttypes.h>
#include <limits.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#if defined(HAVE_SYS_TIME_H) && defined(HAVE_GETTIMEOFDAY)
    #include <sys/times.h>
    #define BENCHMARK_WITH_TIMEVAL
    
    typedef struct timeval benchmark_t;
#else
    #include <time.h>
    
    typedef clock_t benchmark_t;
#endif

#define DEFAULT_BENCHMARK_TIMES 1000000U

#define BENCHMARK(EXPR) \
    do {                                            \
        unsigned i = 0;                             \
        benchmark_t start;                          \
        double elapsed;                             \
                                                    \
        benchmark_begin(&start);                    \
        for (;i < DEFAULT_BENCHMARK_TIMES;++i) {    \
            EXPR;                                   \
        }                                           \
                                                    \
        elapsed = benchmark_end(&start) * 1000;     \
        printf(__FILE__ ":%lu (%s): executed the following %u times in %.2f ms (%f ms each):\n\t%s\n", (unsigned long)__LINE__, __func__, DEFAULT_BENCHMARK_TIMES, elapsed, elapsed / DEFAULT_BENCHMARK_TIMES, # EXPR);   \
    } while (0)

// code duplication to prevent macro expansion in EXPR
#define BENCHMARK_TIMES(TIMES, EXPR) \
    do {                                            \
        unsigned i = 0;                             \
        benchmark_t start;                          \
        double elapsed;                             \
                                                    \
        benchmark_begin(&start);                    \
        for (;i < (TIMES);++i) {                    \
            EXPR;                                   \
        }                                           \
                                                    \
        elapsed = benchmark_end(&start) * 1000;     \
        printf(__FILE__ ":%lu (%s): executed the following %u times in %.2f ms (%f ms each):\n\t%s\n", (unsigned long)__LINE__, __func__, (TIMES), elapsed, elapsed / (TIMES), # EXPR);   \
    } while (0)

#define BENCHMARK_MODULE(NAME) \
    (                                                       \
        printf("*** Benchmarking module %s ***\n", # NAME), \
        NAME ## _benchmark(),                               \
        putc('\n', stdout)                                  \
    )

#define LOG_BENCHMARK(MSG, TIMES, ELAPSED) \
    printf(__FILE__ ":%lu (%s): %s %u times took %.2f ms (%f ms each)\n",   \
        (unsigned long)__LINE__, __func__, (MSG), (TIMES), (ELAPSED),       \
        (ELAPSED) / (TIMES));

#define LOG_TEST(...) \
        LOG_TEST_(__VA_ARGS__, "")

#define LOG_TEST_(MSG, ...) \
    printf(__FILE__ ":%lu (%s): " MSG "%s\n", (unsigned long)__LINE__, __func__, __VA_ARGS__)

#define TEST_MODULE(NAME) \
    (                                                               \
        printf("*** Testing module %s ***\n", # NAME),              \
        NAME ## _test(),                                            \
        printf("*** %s module passed all tests! ***\n\n", # NAME)   \
    )

void benchmark_begin (benchmark_t *start);
double benchmark_end (benchmark_t *start);

#endif
