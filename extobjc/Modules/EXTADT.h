//
//  EXTADT.h
//  extobjc
//
//  Created by Justin Spahr-Summers on 19.06.12.
//  Released into the public domain.
//

#import "metamacros.h"

#define ADT(NAME, ...) \
    /* create typedefs for all of the parameters types used with any constructor */ \
    metamacro_foreach(ADT_typedef_, __VA_ARGS__) \
    \
    /* a type (NameT) for values defined by this ADT */ \
    typedef struct ADT_CURRENT_T { \
        /* an enum listing all the constructor names for this ADT */ \
        /* this will also be how we know the type of this value */ \
        const enum { \
            metamacro_foreach(ADT_enum_, __VA_ARGS__) \
        } tag; \
        \
        /* overlapping storage for all the possible constructors */ \
        /* the tag above determines which parts of this union are in use */ \
        union { \
            metamacro_foreach(ADT_payload_, __VA_ARGS__) \
        }; \
    } NAME ## T; \
    \
    /* defines the actual constructor functions for this type */ \
    metamacro_foreach(ADT_, __VA_ARGS__) \
    \
    /* this structure is used like a simple namespace for the constructors: */ \
    /* ColorT c = Color.Red(); */ \
    const struct { \
        /* as the structure definition, list the function pointers and names of the constructors */ \
        metamacro_foreach(ADT_fptrs_, __VA_ARGS__) \
    } NAME = { \
        /* then fill them in with the actual function addresses */ \
        metamacro_foreach(ADT_fptrinit_, __VA_ARGS__) \
    }; \
    \
    /* implements NSStringFromNameT(), to describe an ADT value */ \
    static inline NSString *NSStringFrom ## NAME ## T (NAME ## T s) { \
        NSMutableString *str = [[NSMutableString alloc] init]; \
        \
        /* only values with parameters will have braces added */ \
        BOOL addedBraces = NO; \
        \
        /* construct the description differently depending on the constructor used */ \
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

/*** implementation details follow ***/

/*
 * The following macros are used to redirect the constructor() invocations that
 * the user provides, so we can re-interpret them many times in different ways,
 * and generate completely different things each time.
 *
 * For example, ADT_typedef_() reroutes constructor(...) to
 * ADT_typedef_constructor(...).
 */
#define ADT_typedef_(INDEX, CONSCALL) \
    ADT_typedef_ ## CONSCALL

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

/*
 * The next few macros create type definitions for every possible parameter type
 * used in the current ADT.
 *
 * We do this so that instead of a type and name for each parameter (e.g.,
 * 'double alpha'), we know just the types for each parameter (e.g., through
 * a type definition of 'double').
 */
#define ADT_typedef_constructor(...) \
    /* add a junk argument for ADT_typedef_constructor_(), in case this constructor has only a name */ \
    /* (necessary because the ... in the argument list needs to match at least one argument) */ \
    ADT_typedef_constructor_(__VA_ARGS__, unsigned char metamacro_concat(metamacro_first(__VA_ARGS__, 0), _unused_))

#define ADT_typedef_constructor_(CONS, ...) \
    metamacro_foreach_cxt(ADT_typedef_param_, CONS, __VA_ARGS__)

#define ADT_typedef_param_(INDEX, CONS, PARAM) \
    /* the form being generated here is similar to 'typedef PTYPE PNAME_JUNK, ALIAS' */ \
    /* with the comma, we've successfully separated the name from the type,
     * and will use the latter via ADT_CURRENT_CONS_ALIAS_T. */ \
    typedef metamacro_concat(PARAM, metamacro_concat(_junk_, __LINE__)), ADT_CURRENT_CONS_ALIAS_T(CONS, INDEX);

/*
 * This macro simply creates an enum entry for the given constructor name.
 */
#define ADT_enum_constructor(...) \
    /* pop off the first variadic argument instead of using a named argument */ \
    /* (necessary because the ... in the argument list needs to match at least one argument) */ \
    metamacro_first(__VA_ARGS__, 0),

/*
 * The "payload" terminology here refers to the data actually stored in an ADT
 * value, and more specifically to the data pertaining only to the constructor
 * that was used.
 *
 * These macros generate the internal layout of the NameT structure.
 *
 * For the following ADT:

ADT(Color,
    constructor(Red),
    constructor(Green),
    constructor(Blue),
    constructor(Gray, double alpha),
    constructor(Other, double r, double g, double b)
);

 * The resulting structure is laid out something like this:

typedef struct {
    const enum { Red, Green, Blue, Gray, Other };

    union {
        struct {
            unsigned char Red_unused_;
        };
        struct Red_aliases {
            unsigned char v0;
        } Red;

        ...

        struct {
            double alpha;
            unsigned char Gray_unused_;
        };
        struct Gray_aliases {
            double v0;
            unsigned char v1;
        } Gray;

        struct {
            double r;
            double g;
            double b;
            unsigned char Other_unused_;
        };
        struct Other_aliases {
            double v0;
            double v1;
            double v2;
            unsigned char v3;
        } Other;
    };
} ColorT;

 * The use of anonymous structures and the containing anonymous union allows
 * a user to access parameter data without intervening steps (e.g.,
 * 'color.alpha', instead of 'color.Gray.alpha'), but does prevent two
 * parameters -- even for different constructors -- from having the same name.
 */
#define ADT_payload_constructor(...) \
    /* add a junk argument for ADT_payload_constructor_(), in case this constructor has only a name */ \
    /* (necessary because the ... in the argument list needs to match at least one argument) */ \
    ADT_payload_constructor_(__VA_ARGS__, unsigned char metamacro_concat(metamacro_first(__VA_ARGS__, 0), _unused_))

#define ADT_payload_constructor_(CONS, ...) \
    /* this is the "real" structure that the user accesses, using the parameter
     * names given in the ADT definition */ \
    struct { \
        metamacro_foreach_cxt(ADT_payload_entry_, CONS, __VA_ARGS__) \
    }; \
    \
    /* this is an internal, exactly overlapping structure that we use to
     * manipulate the parameter values without needing to know their names */ \
    struct { \
        metamacro_foreach_cxt(ADT_payload_alias_, CONS, __VA_ARGS__) \
    } CONS;

#define ADT_payload_entry_(INDEX, CONS, PARAM) \
    /* for the user-facing structure, use the parameters exactly as given */ \
    PARAM;

#define ADT_payload_alias_(INDEX, CONS, PARAM) \
    /* for the internal structure, use consecutively-numbered members */ \
    ADT_CURRENT_CONS_ALIAS_T(CONS, INDEX) v ## INDEX;

/*
 * This macro generates an inline function corresponding to one of the data
 * constructors, which will initialize an ADT value and return it.
 *
 * The first variadic argument here is always the name of the constructor, with
 * the rest of the argument list being the parameters given by the user.
 *
 * Unfortunately, we cannot give an argument name to the constructor, since
 * constructors may have no parameters, and the ... in the macro's argument list
 * needs to always match at least one argument. Instead, metamacro_first() is
 * used to get the constructor name.
 */
#define ADT_constructor(...) \
    static inline struct ADT_CURRENT_T \
    \
    /* the function name (e.g., 'Red_init_') */ \
    metamacro_concat(metamacro_first(__VA_ARGS__, 0), _init_) \
    \
    /* the parameter list for this function */ \
    (metamacro_foreach_cxt(ADT_prototype_, metamacro_first(__VA_ARGS__, 0), __VA_ARGS__)) \
    { \
        /* the actual work of initializing the structure */ \
        /* ADT_initialize0(), the first iteration of the loop, is where this
         * function's local variables are defined */ \
        metamacro_foreach_cxt(ADT_initialize_, metamacro_first(__VA_ARGS__, 0), __VA_ARGS__) \
        return s; \
    }

/*
 * The macros below define each parameter to the constructor function.
 *
 * We use the type definitions created by ADT_typedef_param_() and give them
 * simple, sequentially-numbered names, so we don't have to do any more work to
 * parse or otherwise manipulate the declarations given by the user.
 *
 * Because ADT_prototype0() is used for the constructor name (see its comment
 * for an explanation), our parameters actually need to be shifted down --
 * parameter index 1 actually corresponds to v0, our first value.
 */
#define ADT_prototype_(INDEX, CONS, PARAM) \
    /* dispatches to one of the numbered macros below, based on the INDEX */ \
    metamacro_concat(ADT_prototype, INDEX)(CONS)

#define ADT_prototype0(CONS) \
    /* the constructor name itself is passed as the first argument (again to
     * work around the caveat with variadic arguments), but we don't want it in
     * the parameter list, so we do nothing */

#define ADT_prototype1(CONS) ADT_CURRENT_CONS_ALIAS_T(CONS, 0) v0
#define ADT_prototype2(CONS) , ADT_CURRENT_CONS_ALIAS_T(CONS, 1) v1
#define ADT_prototype3(CONS) , ADT_CURRENT_CONS_ALIAS_T(CONS, 2) v2
#define ADT_prototype4(CONS) , ADT_CURRENT_CONS_ALIAS_T(CONS, 3) v3
#define ADT_prototype5(CONS) , ADT_CURRENT_CONS_ALIAS_T(CONS, 4) v4
#define ADT_prototype6(CONS) , ADT_CURRENT_CONS_ALIAS_T(CONS, 5) v5
#define ADT_prototype7(CONS) , ADT_CURRENT_CONS_ALIAS_T(CONS, 6) v6
#define ADT_prototype8(CONS) , ADT_CURRENT_CONS_ALIAS_T(CONS, 7) v7
#define ADT_prototype9(CONS) , ADT_CURRENT_CONS_ALIAS_T(CONS, 8) v8

/*
 * The macros below generate the initialization code that is actually executed
 * in the constructor function.
 *
 * We merely need to map the given arguments onto the internal structure defined
 * by ADT_payload_alias_(). Because the internal structure is unioned with the
 * user-facing structure, the value can then be read by the user with the name
 * they gave it.
 *
 * As with ADT_prototype*(), our parameter numbers need to be shifted down to
 * correspond to the values in the structure.
 */
#define ADT_initialize_(INDEX, CONS, PARAM) \
    /* dispatches to one of the numbered macros below, based on the INDEX */ \
    metamacro_concat(ADT_initialize, INDEX)(CONS)

#define ADT_initialize0(CONS) \
    /* initialize the tag when the structure is created, because it cannot change later */ \
    struct ADT_CURRENT_T s = { .tag = CONS };

#define ADT_initialize1(CONS) s.CONS.v0 = v0;
#define ADT_initialize2(CONS) s.CONS.v1 = v1;
#define ADT_initialize3(CONS) s.CONS.v2 = v2;
#define ADT_initialize4(CONS) s.CONS.v3 = v3;
#define ADT_initialize5(CONS) s.CONS.v4 = v4;
#define ADT_initialize6(CONS) s.CONS.v5 = v5;
#define ADT_initialize7(CONS) s.CONS.v6 = v6;
#define ADT_initialize8(CONS) s.CONS.v7 = v7;
#define ADT_initialize9(CONS) s.CONS.v8 = v8;

/*
 * The macros below declare and initialize the function pointers used to
 * psuedo-namespace the data constructors.
 *
 * As with ADT_constructor(), the first variadic argument here is always the
 * constructor name. The arguments following are the parameters (as given by the
 * user).
 *
 * The result looks something like this (using the Color example from above):

const struct {
    ColorT (*Red)();
    ColorT (*Green)();
    ColorT (*Blue)();
    ColorT (*Gray)(double v0);
    ColorT (*Other)(double v0, double v1, double v2);
} Color = {
    .Red = &Red_init_,
    .Green = &Green_init_,
    .Blue = &Blue_init_,
    .Gray = &Gray_init_,
    .Other = &Other_init_,
};

 * Thanks goes out to Jon Sterling and his CADT project for this idea:
 * http://www.jonmsterling.com/CADT/
 */
#define ADT_fptrs_constructor(...) \
    struct ADT_CURRENT_T \
    \
    /* the function pointer name (matches that of the constructor) */ \
    (*metamacro_first(__VA_ARGS__, 0)) \
    \
    /* the parameter list for the function -- we just reuse ADT_prototype_() for this */ \
    (metamacro_foreach_cxt(ADT_prototype_, metamacro_first(__VA_ARGS__, 0), __VA_ARGS__));

#define ADT_fptrinit_constructor(...) \
    /* this uses designated initializer syntax to fill in the function pointers
     * with the actual addresses of the inline functions created by ADT_constructor() */ \
    .metamacro_first(__VA_ARGS__, 0) = &metamacro_concat(metamacro_first(__VA_ARGS__, 0), _init_),

/*
 * The following macros are used to generate the code for the
 * NSStringFromNameT() function. They essentially do something similar to
 * an Objective-C implementation of -description.
 *
 * As with ADT_constructor(), the first variadic argument here is always the
 * constructor name. The arguments following are the parameters (as given by the
 * user).
 *
 * As with ADT_prototype*(), our parameter numbers need to be shifted down to
 * correspond to the values in the structure.
 */
#define ADT_tostring_constructor(...) \
        /* try to match each constructor against the value's tag */ \
        case metamacro_first(__VA_ARGS__, 0): { \
            /* now create a description from the constructor name and any parameters */ \
            metamacro_foreach_cxt(ADT_tostring_case_, metamacro_first(__VA_ARGS__, 0), __VA_ARGS__) \
            break; \
        }

#define ADT_tostring_case_(INDEX, CONS, PARAM) \
    /* dispatches to one of the numbered macros below, based on the INDEX */ \
    metamacro_concat(ADT_tostring_case, INDEX)(CONS, PARAM)

#define ADT_tostring_case0(CONS, PARAM) \
    /* this is the first (and possibly) only part of the description: the name
     * of the data constructor */ \
    [str appendString:@ # CONS];

#define ADT_tostring_case1(CONS, PARAM) \
    /* we know now that we have arguments, so we insert a brace (and flip the
     * corresponding flag), then begin by describing the first argument */ \
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

/*
 * The structure tag for the ADT currently being defined. This takes advantage
 * of the fact that the main ADT() is considered to exist on one line, even if
 * it spans multiple lines in an editor.
 *
 * This does prevent multiple ADT() definitions from being provided on the same
 * line, however.
 */
#define ADT_CURRENT_T \
    metamacro_concat(_ADT_, __LINE__)

/*
 * This generates an alias name that can be used to refer to the type of
 * parameter INDEX of constructor CONS.
 *
 * The actual typedef, which is then referred to later, is generated with
 * ADT_typedef_param_().
 */
#define ADT_CURRENT_CONS_ALIAS_T(CONS, INDEX) \
    metamacro_concat(metamacro_concat(ADT_CURRENT_T, _), metamacro_concat(CONS ## _alias, INDEX))

/*
 * Expands to an NSString with a human-readable description of the current value
 * at INDEX, for constructor CONS, in the internal value structure of ADT. PARAM
 * is the parameter declaration originally given by the user.
 */
#define ADT_CURRENT_PARAMETER_DESCRIPTION(CONS, PARAM, ADT, INDEX) \
    [NSString stringWithFormat:@"%@ = %@", \
        /* this is the only place where we actually parse a parameter declaration */ \
        /* we do it here to remove the type from the description, keeping only the name */ \
        [@ # PARAM substringFromIndex:[@ # PARAM rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet] options:NSBackwardsSearch].location + 1], \
        /* convert the parameter type into an Objective-C type encoding, which,
         * along with a pointer to the data, can be used to generate
         * a human-readable description of the actual value */ \
        EXTADT_NSStringFromBytes(&(ADT).CONS.v ## INDEX, @encode(ADT_CURRENT_CONS_ALIAS_T(CONS, INDEX))) \
    ]

NSString *EXTADT_NSStringFromBytes (const void *bytes, const char *encoding);
