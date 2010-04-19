/**
 * libextc enum testcase
 * ExtendedC
 *
 * by Justin Spahr-Summers
 * Copyright (C) 2010
 */

#include "enum_test.h"

enum foo {
    DO_SOMETHING,
    DO_SOMETHING_PLUS_ONE,
    DO_SOMETHING_ELSE = 5,
    OMG_HEX = 0xFF
};

enum_map(foo_map) {
    enum_item(DO_SOMETHING),
    enum_item(DO_SOMETHING_PLUS_ONE),
    enum_item(DO_SOMETHING_ELSE),
    enum_item(OMG_HEX)
};

void enum_benchmark (void) {
    enum foo something;
    BENCHMARK(something = enum_from_string(foo_map, "DO_SOMETHING_PLUS_ONE"));
    BENCHMARK(enum_to_string(foo_map, something));
}

void enum_test (void) {
    enum foo something;
    
    // get enum values from strings!
    LOG_TEST("obtaining enum values from strings");
    
    something = enum_from_string(foo_map, "DO_SOMETHING");
    assert(something == DO_SOMETHING);
    
    something = enum_from_string(foo_map, "DO_SOMETHING_PLUS_ONE");
    assert(something == DO_SOMETHING_PLUS_ONE);
    
    something = enum_from_string(foo_map, "DO_SOMETHING_ELSE");
    assert(something == DO_SOMETHING_ELSE);
    
    something = enum_from_string(foo_map, "OMG_HEX");
    assert(something == OMG_HEX);
    
    const char *str;
    
    // get strings from enum values!
    LOG_TEST("obtaining strings from enum values");
    
    str = enum_to_string(foo_map, DO_SOMETHING);
    assert(strcmp(str, "DO_SOMETHING") == 0);
    
    str = enum_to_string(foo_map, DO_SOMETHING_PLUS_ONE);
    assert(strcmp(str, "DO_SOMETHING_PLUS_ONE") == 0);
    
    str = enum_to_string(foo_map, DO_SOMETHING_ELSE);
    assert(strcmp(str, "DO_SOMETHING_ELSE") == 0);
    
    // the symbolic name doesn't have to be used for this to work:
    LOG_TEST("obtaining strings from integer values (which correspond to enums)");
    
    str = enum_to_string(foo_map, 0xFF);
    assert(strcmp(str, "OMG_HEX") == 0);
}
