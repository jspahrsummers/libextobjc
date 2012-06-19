//
//  EXTADT.h
//  extobjc
//
//  Created by Justin Spahr-Summers on 19.06.12.
//
//

#import "metamacros.h"

#define ADT(NAME, ...) \
    typedef struct metamacro_concat(_ADT_, __LINE__) { \
        void *tag; \
        \
        union { \
            metamacro_foreach(ADT_payload_, __VA_ARGS__) \
        }; \
    } NAME; \
    \
    metamacro_foreach(ADT_, __VA_ARGS__)

#define ADT_payload_(INDEX, CONS) \
    ADT_payload_ ## CONS;

#define ADT_payload_constructor(...) \
    ADT_payload_constructor_(__VA_ARGS__, unsigned char)

#define ADT_payload_constructor_(NAME, ...) \
    struct metamacro_concat(metamacro_concat(_ADT_, __LINE__), NAME) { \
        metamacro_foreach_recursive(ADT_payload_entry_, __VA_ARGS__) \
    } NAME

#define ADT_payload_entry_(INDEX, TYPE) \
    TYPE v ## INDEX;

#define ADT_(INDEX, CONS) \
    ADT_ ## CONS;

#define ADT_constructor(...) \
    static inline struct metamacro_concat(_ADT_, __LINE__) \
    metamacro_foreach_recursive(ADT_prototype_, __VA_ARGS__) \
    ) { \
        struct metamacro_concat(_ADT_, __LINE__) s; \
        \
        metamacro_foreach_recursive(ADT_initialize_, __VA_ARGS__) \
        \
        return s; \
    }

#define ADT_prototype_(INDEX, ARG) \
    metamacro_concat(ADT_prototype, INDEX)(ARG)

#define ADT_prototype0(NAME) NAME (
#define ADT_prototype1(TYPE) TYPE v0
#define ADT_prototype2(TYPE) TYPE v1
#define ADT_prototype3(TYPE) TYPE v2
#define ADT_prototype4(TYPE) TYPE v3
#define ADT_prototype5(TYPE) TYPE v4
#define ADT_prototype6(TYPE) TYPE v5
#define ADT_prototype7(TYPE) TYPE v6
#define ADT_prototype8(TYPE) TYPE v7
#define ADT_prototype9(TYPE) TYPE v8

#define ADT_initialize_(INDEX, ARG) \
    metamacro_concat(ADT_initialize, INDEX)(ARG);

#define ADT_initialize0(NAME) \
        s.tag = (__typeof__(s.tag))&NAME; \
        struct metamacro_concat(metamacro_concat(_ADT_, __LINE__), NAME) *entry __attribute__((unused)) = &s.NAME

#define ADT_initialize1(TYPE) entry->v0 = v0
#define ADT_initialize2(TYPE) entry->v1 = v1
#define ADT_initialize3(TYPE) entry->v2 = v2
#define ADT_initialize4(TYPE) entry->v3 = v3
#define ADT_initialize5(TYPE) entry->v4 = v4
#define ADT_initialize6(TYPE) entry->v5 = v5
#define ADT_initialize7(TYPE) entry->v6 = v6
#define ADT_initialize8(TYPE) entry->v7 = v7
#define ADT_initialize9(TYPE) entry->v8 = v8
