//
//  EXTTuple.h
//  extobjc
//
//  Created by Justin Spahr-Summers on 18.06.12.
//  Copyright (C) 2012 Justin Spahr-Summers.
//  Released under the MIT license.
//

#import "metamacros.h"

/**
 * Returns an \c EXTTupleN structure holding the given objects, where \c N is
 * the number of arguments given.
 *
 * Tuples cannot contain primitives, but may contain \c nil values.
 */
#define tuple(...) \
    ((metamacro_concat(EXTTuple, metamacro_argcount(__VA_ARGS__))){ __VA_ARGS__ })

/**
 * Collects variables to be used for multiple assignment with #unpack. This
 * macro _must_ be followed by = and a call to #unpack.
 *
 * The result of the multiple assignment (i.e., if used as part of a larger
 * expression) will be the first object of the tuple.
 *
 * @code

    NSString *str;
    NSNumber *num;

    // this could also be the return value of a method or something similar
    EXTTuple2 t = tuple(@"foo", @5);

    multivar(str, num) = unpack(t);

 * @endcode
 */
#define multivar(...) \
    ({ \
        metamacro_foreach(multivar_,, __VA_ARGS__) \
        metamacro_concat(EXTTuple, metamacro_argcount(__VA_ARGS__)) t_, *tptr_ = &t_; \
        \
        void (^unpackToVariables)(void) = ^{ \
            metamacro_foreach(unpack_,, __VA_ARGS__) \
        }; \
        \
        t_

/**
 * Unpacks the given EXTTuple into the variables previously listed with
 * #multivar.
 *
 * See #multivar for an example.
 */
#define unpack(TUPLE) \
        TUPLE; \
        unpackToVariables(); \
        \
        t_.v0;\
    })

/*** implementation details follow ***/
#define EXTTuple(INDEX, COUNT) \
    typedef struct { \
        metamacro_for_cxt(COUNT, EXTTupleIndex_,,) \
    } metamacro_concat(EXTTuple, COUNT);

#define EXTTupleIndex_(INDEX, CONTEXT) \
        __unsafe_unretained id v ## INDEX;

#define multivar_(INDEX, VAR) \
    __typeof__(VAR) *VAR ## _ptr_ = &VAR;

#define unpack_(INDEX, VAR) \
    *VAR ## _ptr_ = tptr_->v ## INDEX;

// creates type definitions for EXTTuple1 through EXTTuple20
metamacro_foreach(EXTTuple,, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20);
