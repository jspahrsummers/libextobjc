//
//  EXTADT.h
//  extobjc
//
//  Created by Justin Spahr-Summers on 19.06.12.
//  Released into the public domain.
//

#import "metamacros.h"

#define ADT(NAME, ...) \
    metamacro_foreach(ADT_predef_, __VA_ARGS__) \
    \
    typedef struct ADT_CURRENT_T { \
        const enum { \
            metamacro_foreach(ADT_enum_, __VA_ARGS__) \
        } tag; \
        \
        union { \
            metamacro_foreach(ADT_payload_, __VA_ARGS__) \
        }; \
    } NAME ## T; \
    \
    metamacro_foreach(ADT_, __VA_ARGS__) \
    \
    const struct { \
        metamacro_foreach(ADT_fptrs_, __VA_ARGS__) \
    } NAME = { \
        metamacro_foreach(ADT_fptrinit_, __VA_ARGS__) \
    }; \
    \
    static inline NSString *NSStringFrom ## NAME ## T (NAME ## T s) { \
        NSMutableString *str = [[NSMutableString alloc] init]; \
        BOOL addedBraces = NO; \
        \
        switch (s.tag) { \
            metamacro_foreach(ADT_tostring_, __VA_ARGS__) \
            default: \
                return nil; \
        } \
        \
        if (addedBraces) \
            [str appendString:@" }"]; \
        \
        return str; \
    }

#define ADT_predef_(INDEX, CONSCALL) \
    ADT_predef_ ## CONSCALL

#define ADT_enum_(INDEX, CONSCALL) \
    ADT_enum_ ## CONSCALL

#define ADT_payload_(INDEX, CONSCALL) \
    ADT_payload_ ## CONSCALL

#define ADT_(INDEX, CONSCALL) \
    ADT_ ## CONSCALL

#define ADT_fptrs_(INDEX, CONSCALL) \
    ADT_fptrs_ ## CONSCALL

#define ADT_fptrinit_(INDEX, CONSCALL) \
    ADT_fptrinit_ ## CONSCALL

#define ADT_tostring_(INDEX, CONSCALL) \
    ADT_tostring_ ## CONSCALL

#define ADT_predef_constructor(...) \
    ADT_predef_constructor_(__VA_ARGS__, unsigned char metamacro_concat(metamacro_first(__VA_ARGS__, 0), _unused_))

#define ADT_predef_constructor_(CONS, ...) \
    metamacro_foreach_cxt(ADT_predef_typedef_, CONS, __VA_ARGS__)

#define ADT_predef_typedef_(INDEX, CONS, PARAM) \
    typedef metamacro_concat(PARAM, metamacro_concat(_junk_, __LINE__)), ADT_CURRENT_CONS_ALIAS_T(CONS, INDEX);

#define ADT_enum_constructor(...) \
    metamacro_first(__VA_ARGS__, 0),

#define ADT_payload_constructor(...) \
    ADT_payload_constructor_(__VA_ARGS__, unsigned char metamacro_concat(metamacro_first(__VA_ARGS__, 0), _unused_))

#define ADT_payload_constructor_(CONS, ...) \
    struct { \
        metamacro_foreach_cxt(ADT_payload_entry_, CONS, __VA_ARGS__) \
    }; \
    \
    struct ADT_CURRENT_CONS_ALIASES_T(CONS) { \
        metamacro_foreach_cxt(ADT_payload_alias_, CONS, __VA_ARGS__) \
    } CONS;

#define ADT_payload_entry_(INDEX, CONS, PARAM) \
    PARAM;

#define ADT_payload_alias_(INDEX, CONS, PARAM) \
    ADT_CURRENT_CONS_ALIAS_T(CONS, INDEX) v ## INDEX;

#define ADT_constructor(...) \
    static inline struct ADT_CURRENT_T \
    metamacro_concat(metamacro_first(__VA_ARGS__, 0), _init_) (metamacro_foreach_cxt(ADT_prototype_, metamacro_first(__VA_ARGS__, 0), __VA_ARGS__)) \
    { \
        metamacro_foreach_cxt(ADT_initialize_, metamacro_first(__VA_ARGS__, 0), __VA_ARGS__) \
        return s; \
    }

#define ADT_prototype_(INDEX, CONS, PARAM) \
    metamacro_concat(ADT_prototype, INDEX)(CONS)

#define ADT_prototype0(CONS)
#define ADT_prototype1(CONS) ADT_CURRENT_CONS_ALIAS_T(CONS, 0) v0
#define ADT_prototype2(CONS) , ADT_CURRENT_CONS_ALIAS_T(CONS, 1) v1
#define ADT_prototype3(CONS) , ADT_CURRENT_CONS_ALIAS_T(CONS, 2) v2
#define ADT_prototype4(CONS) , ADT_CURRENT_CONS_ALIAS_T(CONS, 3) v3
#define ADT_prototype5(CONS) , ADT_CURRENT_CONS_ALIAS_T(CONS, 4) v4
#define ADT_prototype6(CONS) , ADT_CURRENT_CONS_ALIAS_T(CONS, 5) v5
#define ADT_prototype7(CONS) , ADT_CURRENT_CONS_ALIAS_T(CONS, 6) v6
#define ADT_prototype8(CONS) , ADT_CURRENT_CONS_ALIAS_T(CONS, 7) v7
#define ADT_prototype9(CONS) , ADT_CURRENT_CONS_ALIAS_T(CONS, 8) v8

#define ADT_initialize_(INDEX, CONS, PARAM) \
    metamacro_concat(ADT_initialize, INDEX)(CONS)

#define ADT_initialize0(CONS) \
    struct ADT_CURRENT_T s = { .tag = CONS }; \
    struct ADT_CURRENT_CONS_ALIASES_T(CONS) *entry __attribute__((unused)) = &s.CONS;

#define ADT_initialize1(CONS) entry->v0 = v0;
#define ADT_initialize2(CONS) entry->v1 = v1;
#define ADT_initialize3(CONS) entry->v2 = v2;
#define ADT_initialize4(CONS) entry->v3 = v3;
#define ADT_initialize5(CONS) entry->v4 = v4;
#define ADT_initialize6(CONS) entry->v5 = v5;
#define ADT_initialize7(CONS) entry->v6 = v6;
#define ADT_initialize8(CONS) entry->v7 = v7;
#define ADT_initialize9(CONS) entry->v8 = v8;

#define ADT_fptrs_constructor(...) \
    struct ADT_CURRENT_T (*metamacro_first(__VA_ARGS__, 0)) (metamacro_foreach_cxt(ADT_prototype_, metamacro_first(__VA_ARGS__, 0), __VA_ARGS__));

#define ADT_fptrinit_constructor(...) \
    .metamacro_first(__VA_ARGS__, 0) = &metamacro_concat(metamacro_first(__VA_ARGS__, 0), _init_),

#define ADT_tostring_constructor(...) \
        case metamacro_first(__VA_ARGS__, 0): { \
            metamacro_foreach_cxt(ADT_tostring_case_, metamacro_first(__VA_ARGS__, 0), __VA_ARGS__) \
            break; \
        }

#define ADT_tostring_case_(INDEX, CONS, PARAM) \
    metamacro_concat(ADT_tostring_case, INDEX)(CONS, PARAM)

#define ADT_tostring_case0(CONS, PARAM) [str appendString:@ # CONS];

#define ADT_tostring_case1(CONS, PARAM) \
    [str appendFormat:@" { %@", ADT_CURRENT_PARAMETER_DESCRIPTION(CONS, PARAM, s, 0)]; \
    addedBraces = YES;

#define ADT_tostring_case2(CONS, PARAM) [str appendFormat: @", %@", ADT_CURRENT_PARAMETER_DESCRIPTION(CONS, PARAM, s, 1)];
#define ADT_tostring_case3(CONS, PARAM) [str appendFormat: @", %@", ADT_CURRENT_PARAMETER_DESCRIPTION(CONS, PARAM, s, 2)];
#define ADT_tostring_case4(CONS, PARAM) [str appendFormat: @", %@", ADT_CURRENT_PARAMETER_DESCRIPTION(CONS, PARAM, s, 3)];
#define ADT_tostring_case5(CONS, PARAM) [str appendFormat: @", %@", ADT_CURRENT_PARAMETER_DESCRIPTION(CONS, PARAM, s, 4)];
#define ADT_tostring_case6(CONS, PARAM) [str appendFormat: @", %@", ADT_CURRENT_PARAMETER_DESCRIPTION(CONS, PARAM, s, 5)];
#define ADT_tostring_case7(CONS, PARAM) [str appendFormat: @", %@", ADT_CURRENT_PARAMETER_DESCRIPTION(CONS, PARAM, s, 6)];
#define ADT_tostring_case8(CONS, PARAM) [str appendFormat: @", %@", ADT_CURRENT_PARAMETER_DESCRIPTION(CONS, PARAM, s, 7)];
#define ADT_tostring_case9(CONS, PARAM) [str appendFormat: @", %@", ADT_CURRENT_PARAMETER_DESCRIPTION(CONS, PARAM, s, 8)];

#define ADT_CURRENT_T \
    metamacro_concat(_ADT_, __LINE__)

#define ADT_CURRENT_CONS_ALIASES_T(CONS) \
    metamacro_concat(metamacro_concat(ADT_CURRENT_T, _), metamacro_concat(CONS, _aliases))

#define ADT_CURRENT_CONS_ALIAS_T(CONS, INDEX) \
    metamacro_concat(ADT_CURRENT_CONS_ALIASES_T(CONS), INDEX)

#define ADT_CURRENT_PARAMETER_DESCRIPTION(CONS, PARAM, ADT, INDEX) \
    [NSString stringWithFormat:@"%@ = %@", \
        [@ # PARAM substringFromIndex:[@ # PARAM rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet] options:NSBackwardsSearch].location + 1], \
        EXTADT_NSStringFromBytes(&(ADT).CONS.v ## INDEX, @encode(ADT_CURRENT_CONS_ALIAS_T(CONS, INDEX))) \
    ]

NSString *EXTADT_NSStringFromBytes (const void *bytes, const char *encoding);
