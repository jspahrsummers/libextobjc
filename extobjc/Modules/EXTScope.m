//
//  EXTScope.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-05-04.
//  Released into the public domain.
//

#import "EXTScope.h"

void ext_executeCleanupBlock (__strong ext_cleanupBlock_t *block) {
    (*block)();
}

id<NSLocking> ext_lockAndReturn (id<NSLocking> lock) {
    [lock lock];
    return lock;
}

void ext_releaseScopeLock (__strong id<NSLocking> *lockPtr) {
    [*lockPtr unlock];
}

