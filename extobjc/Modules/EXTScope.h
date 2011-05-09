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
	ext_cleanupBlock_t metamacro_concat(ext_exitBlock_, __LINE__) __attribute__((cleanup(ext_executeCleanupBlock), unused)) = ^

/**
 * Used in the declaration of an object variable, \c scope will ensure that the
 * value is released when the current scope exits. The object will be released
 * regardless of how the scope is exited, including from exceptions, \c goto, \c
 * return, \c break, and \c continue.
 *
 * In addition to being more efficient than an autorelease pool, \c scope also
 * makes it easier to deterministically release scarce resources, including file
 * handles, sockets, mutexes, database connections, etc.
 *
 * @code

// this file handle will be automatically closed and released when the current scope ends
scope NSFileHandle *handle = [[NSFileHandle alloc] initWithFileDescriptor:fildes];

 * @endcode
 */
#define scope \
	__attribute__((cleanup(ext_releaseScopeObject)))

/*** implementation details follow ***/
typedef void (^ext_cleanupBlock_t)();

void ext_executeCleanupBlock (ext_cleanupBlock_t *block);
void ext_releaseScopeObject (id *objPtr);

