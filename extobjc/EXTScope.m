//
//  EXTScope.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-05-04.
//  Copyright (C) 2012 Justin Spahr-Summers.
//  Released under the MIT license.
//

#import "EXTScope.h"

#if defined(__cplusplus)
extern "C" {
#endif
    void ext_executeCleanupBlock (__strong ext_cleanupBlock_t *block) {
        (*block)();
    }
#if defined(__cplusplus)
}
#endif