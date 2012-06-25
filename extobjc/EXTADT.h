//
//  EXTADT.h
//  extobjc
//
//  Created by Justin Spahr-Summers on 19.06.12.
//  Released into the public domain.
//

#import "metamacros.h"
#import "EXTRuntimeExtensions.h"

/**
 * Creates an algebraic data type with the given name and one or more data
 * constructors. Each constructor should be specified using the \c constructor()
 * macro, the first argument of which is the constructor name. Zero or more
 * parameters, which should look just like variable declarations (e.g., "int x")
 * may follow the constructor name.
 *
 * Among many other things, this can be used to create type-safe enumerations
 * which can be printed as strings (and optionally associated with data).
 *
 * This macro will create:
 *
 *  - A structure type NameT, where "Name" is the first argument to this macro.
 *  Instances of the structure will each contain a member "tag", which is filled
 *  in with the enum value of the constructor used to create the value.
 *  - A function NSStringFromNameT(), which will convert an ADT value into
 *  a human-readable string.
 *  - And, for each constructor Cons:
 *      - An enum value Cons, which can be used to refer to that data constructor.
 *      - A function Name.Cons(...), which accepts the parameters of the
 *      constructor and returns a new NameT structure.
 *      - Members (properties) for each of the constructor's named parameters,
 *      which can be used to get and set the data associated with that
 *      constructor.
 *
 * @code

// this invocation:
ADT(Color,
    constructor(Red),
    constructor(Green),
    constructor(Blue),
    constructor(Gray, double alpha),
    constructor(Other, double r, double g, double b)
);

// produces (effectively) these definitions:
typedef struct {
    enum { Red, Green, Blue, Gray, Other } tag;

    union {
        struct {
            double alpha;
        }

        struct {
            double r;
            double g;
            double b;
        }
    }
} ColorT;

NSString *NSStringFromColorT (ColorT c);

ColorT Color.Red ();
ColorT Color.Green ();
ColorT Color.Blue ();
ColorT Color.Gray (double alpha);
ColorT Color.Other (double r, double g, double b);

 * @endcode
 *
 * @note Each constructor parameter must have a name that is unique among all of
 * the ADT's constructors, so that dot-syntax (e.g., "color.r") works without
 * needing to prefix the name of the data constructor (e.g., "color.Other.r").
 *
 * @warning Accessing members that do not correspond to the structure's tag
 * (e.g., parameter data from other constructors) is considered undefined
 * behavior.
 *
 * @bug Currently, only up to nineteen data constructors are supported, and each
 * constructor may only have up to nineteen parameters. This is a limitation
 * imposed primarily by #metamacro_foreach_cxt.
 *
 * @bug ADT parameters cannot currently be declared with asterisks (including
 * patterns like "const char *" or "NSString *"). This can be worked around by
 * using typedefs (e.g., "typedef const char *my_type_t;") or less-specific
 * types (like "id") instead.
 *
 * @bug An ADT value nested within another ADT value will not be very readable
 * when printed out with the generated NSStringFrom… function. All other data
 * will behave correctly.
 */
#define ADT(NAME, ...) \
    /* create typedefs for all of the parameters types used with any constructor */ \
    /* this will append ADT_typedef_ to each constructor() call, thus invoking
     * ADT_typedef_constructor() instead */ \
    metamacro_foreach_concat(ADT_typedef_,, __VA_ARGS__) \
    \
    /* a type (NameT) for values defined by this ADT */ \
    typedef struct ADT_CURRENT_T { \
        /* an enum listing all the constructor names for this ADT */ \
        /* this will also be how we know the type of this value */ \
        const enum { \
            metamacro_foreach_concat(ADT_enum_,, __VA_ARGS__) \
        } tag; \
        \
        /* overlapping storage for all the possible constructors */ \
        /* the tag above determines which parts of this union are in use */ \
        union { \
            metamacro_foreach_concat(ADT_payload_,, __VA_ARGS__) \
        }; \
    } NAME ## T; \
    \
    /* defines the actual constructor functions for this type */ \
    metamacro_foreach_concat(ADT_,, __VA_ARGS__) \
    \
    /* this structure is used like a simple namespace for the constructors: */ \
    /* ColorT c = Color.Red(); */ \
    const struct { \
        /* as the structure definition, list the function pointers and names of the constructors */ \
        metamacro_foreach_concat(ADT_fptrs_,, __VA_ARGS__) \
    } NAME = { \
        /* then fill them in with the actual function addresses */ \
        metamacro_foreach_concat(ADT_fptrinit_,, __VA_ARGS__) \
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
            metamacro_foreach_concat(ADT_tostring_,, __VA_ARGS__) \
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
 * The next few macros create type definitions for every possible parameter type
 * used in the current ADT.
 *
 * We do this so that instead of a type and name for each parameter (e.g.,
 * 'double alpha'), we know just the types for each parameter (e.g., through
 * a type definition of 'double').
 */
#define ADT_typedef_constructor(...) \
    /* our first argument will always be the constructor name, so if we only
     * have one argument, we only have a constructor */ \
    metamacro_if_eq(1, metamacro_argcount(__VA_ARGS__)) \
        (/* no parameters, don't add any typedefs */) \
        ( \
            /* there are actually parameters */ \
            ADT_typedef_constructor_(__VA_ARGS__) \
        )

#define ADT_typedef_constructor_(CONS, ...) \
    metamacro_foreach_cxt_recursive(ADT_typedef_iter,, CONS, __VA_ARGS__)

#define ADT_typedef_iter(INDEX, CONS, PARAM) \
    typedef union { \
        union { \
            PARAM; \
            \
            unsigned char bytes[sizeof( \
                struct __attribute__((packed)) { PARAM; } \
            )]; \
        } payload; \
        \
        PARAM; \
    } __attribute__((transparent_union)) ADT_CURRENT_CONS_ALIAS_T(CONS, INDEX);

/*
 * This macro simply creates an enum entry for the given constructor name.
 */
#define ADT_enum_constructor(...) \
    /* pop off the first variadic argument instead of using a named argument */ \
    /* (necessary because the ... in the argument list needs to match at least one argument) */ \
    metamacro_head(__VA_ARGS__),

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
    const enum { Red, Green, Blue, Gray, Other } tag;

    union {
        struct {
            double alpha;
        };
        struct Gray_aliases {
            double v0;
        } Gray;

        struct {
            double r;
            double g;
            double b;
        };
        struct Other_aliases {
            double v0;
            double v1;
            double v2;
        } Other;
    };
} ColorT;

 * The use of anonymous structures and the containing anonymous union allows
 * a user to access parameter data without intervening steps (e.g.,
 * 'color.alpha', instead of 'color.Gray.alpha'), but does prevent two
 * parameters -- even for different constructors -- from having the same name.
 */
#define ADT_payload_constructor(...) \
    /* our first argument will always be the constructor name, so if we only
     * have one argument, we only have a constructor */ \
    metamacro_if_eq(1, metamacro_argcount(__VA_ARGS__)) \
        (/* this constructor has only a name, don't add any structures */)\
        ( \
            /* create structures for the parameters that exist */ \
            ADT_payload_constructor_(__VA_ARGS__) \
        )

#define ADT_payload_constructor_(CONS, ...) \
    /* this is the "real" structure that the user accesses, using the parameter
     * names given in the ADT definition */ \
    struct { \
        metamacro_foreach_cxt_recursive(ADT_payload_entry_iter,,, __VA_ARGS__) \
    }; \
    \
    /* this is an internal, exactly overlapping structure that we use to
     * manipulate the parameter values without needing to know their names */ \
    struct { \
        metamacro_for_cxt(metamacro_argcount(__VA_ARGS__), ADT_payload_alias_iter,, CONS) \
    } CONS;

#define ADT_payload_entry_iter(INDEX, CONTEXT, PARAM) \
    /* for the user-facing structure, use the parameters exactly as given */ \
    PARAM;

#define ADT_payload_alias_iter(INDEX, CONS) \
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
 * needs to always match at least one argument. Instead, metamacro_head() is
 * used to get the constructor name.
 */
#define ADT_constructor(...) \
    static inline struct ADT_CURRENT_T \
    \
    /* the function name (e.g., 'Red_init_') */ \
    metamacro_concat(metamacro_head(__VA_ARGS__), _init_) \
    \
    /* the parameter list for this function */ \
    (metamacro_foreach_cxt_recursive(ADT_prototype_iter,, metamacro_head(__VA_ARGS__), __VA_ARGS__)) \
    { \
        /* the actual work of initializing the structure */ \
        /* the local variables for this function are defined in the first iteration of the loop */ \
        metamacro_foreach_cxt_recursive(ADT_initialize_iter,, metamacro_head(__VA_ARGS__), __VA_ARGS__) \
        return s; \
    }

/*
 * The macros below define each parameter to the constructor function.
 *
 * We use the type definitions created by ADT_typedef_iter() and give them
 * simple, sequentially-numbered names, so we don't have to do any more work to
 * parse or otherwise manipulate the declarations given by the user.
 *
 * Because the first argument to metamacro_foreach_recursive_cxt() is the
 * constructor name, our parameters actually need to be shifted down --
 * index 1 actually corresponds to v0, our first parameter.
 */
#define ADT_prototype_iter(INDEX, CONS, PARAM) \
    metamacro_if_eq(0, INDEX) \
        (/* the constructor name itself is passed as the first argument (again to
         * work around the caveat with variadic arguments), but we don't want it in
         * the parameter list, so we do nothing */) \
        ( \
            /* insert a comma for every argument after index 1 */ \
            metamacro_if_eq_recursive(1, INDEX)()(,) \
            \
            /* parameter type */ \
            ADT_CURRENT_CONS_ALIAS_T(CONS, metamacro_dec(INDEX)) \
            \
            /* parameter name */ \
            metamacro_concat(v, metamacro_dec(INDEX)) \
        )

/*
 * The macros below generate the initialization code that is actually executed
 * in the constructor function.
 *
 * We merely need to map the given arguments onto the internal structure defined
 * by ADT_payload_alias_iter(). Because the internal structure is unioned with the
 * user-facing structure, the value can then be read by the user with the name
 * they gave it.
 *
 * As with ADT_prototype*(), our parameter numbers need to be shifted down to
 * correspond to the values in the structure.
 */
#define ADT_initialize_iter(INDEX, CONS, PARAM) \
    metamacro_if_eq(0, INDEX) \
        ( \
            /* initialize the tag when the structure is created, because it cannot change later */ \
            struct ADT_CURRENT_T s = { .tag = CONS } \
        ) \
        (s.CONS.metamacro_concat(v, metamacro_dec(INDEX)) = metamacro_concat(v, metamacro_dec(INDEX))) \
    ;

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
    (*metamacro_head(__VA_ARGS__)) \
    \
    /* the parameter list for the function -- we just reuse ADT_prototype_iter() for this */ \
    (metamacro_foreach_cxt_recursive(ADT_prototype_iter,, metamacro_head(__VA_ARGS__), __VA_ARGS__));

#define ADT_fptrinit_constructor(...) \
    /* this uses designated initializer syntax to fill in the function pointers
     * with the actual addresses of the inline functions created by ADT_constructor() */ \
    .metamacro_head(__VA_ARGS__) = &metamacro_concat(metamacro_head(__VA_ARGS__), _init_),

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
        case metamacro_head(__VA_ARGS__): { \
            /* now create a description from the constructor name and any parameters */ \
            metamacro_foreach_cxt_recursive(ADT_tostring_iter,, metamacro_head(__VA_ARGS__), __VA_ARGS__) \
            break; \
        }

#define ADT_tostring_iter(INDEX, CONS, PARAM) \
    /* dispatches to one of the case macros below, based on the INDEX */ \
    metamacro_if_eq(0, INDEX) \
        (ADT_tostring_case0(CONS, PARAM)) \
        (metamacro_if_eq_recursive(1, INDEX) \
            (ADT_tostring_case1(CONS, PARAM)) \
            (ADT_tostring_defaultcase(INDEX, CONS, PARAM)) \
        )

#define ADT_tostring_case0(CONS, PARAM) \
    /* this is the first (and possibly) only part of the description: the name
     * of the data constructor */ \
    [str appendString:@ # CONS];

#define ADT_tostring_case1(CONS, PARAM) \
    /* we know now that we have arguments, so we insert a brace (and flip the
     * corresponding flag), then begin by describing the first argument */ \
    [str appendFormat:@" { %@", ADT_CURRENT_PARAMETER_DESCRIPTION(CONS, PARAM, s, 0)]; \
    addedBraces = YES;

#define ADT_tostring_defaultcase(INDEX, CONS, PARAM) \
    [str appendFormat: @", %@", ADT_CURRENT_PARAMETER_DESCRIPTION(CONS, PARAM, s, metamacro_dec(INDEX))];

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
 * ADT_typedef_iter().
 */
#define ADT_CURRENT_CONS_ALIAS_T(CONS, INDEX) \
    metamacro_concat(metamacro_concat(ADT_CURRENT_T, _), metamacro_concat(CONS ## _alias, INDEX))

#define ADT_CURRENT_CONS_ALIAS_BYTES_T(CONS, INDEX) \
    metamacro_concat(CONS ## _alias_, INDEX)

/*
 * Expands to an NSString with a human-readable description of the current value
 * at INDEX, for constructor CONS, in the internal value structure of ADT. PARAM
 * is the parameter declaration originally given by the user.
 */
#define ADT_CURRENT_PARAMETER_DESCRIPTION(CONS, PARAM, ADT, INDEX) \
    [NSString stringWithFormat:@"%@ = %@", \
        /* this is the only place where we actually parse a parameter declaration */ \
        /* we do it here to remove the type from the description, keeping only the name */ \
        [@ # PARAM substringFromIndex:[@ # PARAM rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] options:NSBackwardsSearch].location + 1], \
        /* convert the parameter type into an Objective-C type encoding, which,
         * along with a pointer to the data, can be used to generate
         * a human-readable description of the actual value */ \
        ext_stringFromTypedBytes(&(ADT).CONS.metamacro_concat(v, INDEX), @encode(ADT_CURRENT_CONS_ALIAS_T(CONS, INDEX))) \
    ]
