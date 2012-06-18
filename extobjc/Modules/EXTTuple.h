/*
 *  EXTTuple.h
 *  extobjc
 *
 *  Created by Justin Spahr-Summers on 18.06.12.
 *  Released into the public domain.
 */

#import "metamacros.h"

/**
 * Returns an \c EXTTupleN structure holding the given arguments, where \c N is
 * the number of arguments given.
 */
#define tuple(...) \
    ((metamacro_concat(EXTTuple, metamacro_argcount(__VA_ARGS__))){ __VA_ARGS__ })

/*** implementation details follow ***/
#define EXTTuple_(...) \
    struct { \
        metamacro_foreach(EXTTupleIndex_, __VA_ARGS__) \
    }

#define EXTTupleIndex_(INDEX, ...) \
        __unsafe_unretained id v ## INDEX;

typedef EXTTuple_(0) EXTTuple1;
typedef EXTTuple_(0, 1) EXTTuple2;
typedef EXTTuple_(0, 1, 2) EXTTuple3;
typedef EXTTuple_(0, 1, 2, 3) EXTTuple4;
typedef EXTTuple_(0, 1, 2, 3, 4) EXTTuple5;
typedef EXTTuple_(0, 1, 2, 3, 4, 5) EXTTuple6;
typedef EXTTuple_(0, 1, 2, 3, 4, 5, 6) EXTTuple7;
typedef EXTTuple_(0, 1, 2, 3, 4, 5, 6, 7) EXTTuple8;
typedef EXTTuple_(0, 1, 2, 3, 4, 5, 6, 7, 8) EXTTuple9;
