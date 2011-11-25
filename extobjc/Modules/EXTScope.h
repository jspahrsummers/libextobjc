//
//  EXTScope.h
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-05-04.
//  Released into the public domain.
//

#import "metamacros.h"

/**
 * \@onExit defines some code to be executed when the current scope exits. The
 * code must be enclosed in braces and terminated with a semicolon, and will be
 * executed regardless of how the scope is exited, including from exceptions,
 * \c goto, \c return, \c break, and \c continue.
 *
 * Provided code will go into a block to be executed later. Keep this in mind as
 * it pertains to memory management, restrictions on assignment, etc. Because
 * the code is used within a block, \c return is a legal (though perhaps
 * confusing) way to exit the cleanup block early.
 *
 * Multiple \@onExit statements in the same scope are executed in reverse
 * lexical order. This helps when pairing resource acquisition with \@onExit
 * statements, as it guarantees teardown in the opposite order of acquisition.
 *
 * @note This statement cannot be used within scopes defined without braces
 * (like a one line \c if). In practice, this is not an issue, since \@onExit is
 * a useless construct in such a case anyways.
 */
#define onExit \
    try {} @finally {} \
    __strong ext_cleanupBlock_t metamacro_concat(ext_exitBlock_, __LINE__) __attribute__((cleanup(ext_executeCleanupBlock), unused)) = ^

/**
 * Given an object that conforms to the \c NSLocking protocol, this will acquire
 * the lock for the remaining lifetime of the current scope. The object will be
 * unlocked when the scope ends, regardless of how the scope is exited,
 * including from exceptions, \c goto, \c return, \c break, and \c continue.
 */
#define lockForScope(LOCK) \
    __strong id<NSLocking> metamacro_concat(ext_scopeLock_, __LINE__) __attribute__((cleanup(ext_releaseScopeLock), unused)) = ext_lockAndReturn(LOCK)

/**
 * Given an object that conforms to the \c NSLocking protocol and implements an
 * additional \c tryLock method, this statement will attempt to acquire the
 * lock. If the lock could not be immediately acquired (according to the
 * semantics of \c tryLock as implemented on \a LOCK), nothing happens, and the
 * given statement body is skipped . If the lock \e is acquired, the given
 * statement body is executed, and the lock automatically released afterward.
 * The object is guaranteed to be unlocked when the scope of the given statement
 * ends, regardless of how that scope is exited, including from exceptions, \c
 * goto, \c return, \c break, and \c continue.
 *
 * @note This macro functions like a built-in statement and, as such, \c break
 * and \c continue have special meaning within it. Both will exit the scope of
 * the ifTryLock() statement, unlocking \a LOCK in the process. This does mean,
 * however, that any enclosing loops cannot be broken or continued from within
 * ifTryLock().
 */
#define ifTryLock(LOCK) \
    for (BOOL ext_done_ = NO; !ext_done_; ext_done_ = YES) \
        for (__strong id ext_scopeLock_ __attribute__((cleanup(ext_releaseScopeLock))) = (LOCK); !ext_done_ && [ext_scopeLock_ tryLock]; ext_done_ = YES)

/*** implementation details follow ***/
typedef void (^ext_cleanupBlock_t)();

void ext_executeCleanupBlock (__strong ext_cleanupBlock_t *block);
id<NSLocking> ext_lockAndReturn (id<NSLocking> lock);
void ext_releaseScopeLock (__strong id<NSLocking> *lockPtr);

