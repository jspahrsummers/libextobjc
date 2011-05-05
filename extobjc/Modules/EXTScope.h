//
//  EXTScope.h
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-05-04.
//  Released into the public domain.
//

/**
 * \@onExit defines some code to be executed when the current scope exits. The
 * code must be enclosed in braces and terminated with a semicolon, and will be
 * executed regardless of how the scope is exited, including from exceptions,
 * \c goto, \c return, \c break, and \c continue.
 */
#define onExit \
	try {} @finally {} \
	ext_cleanupBlock_t ext_exitBlock_ ## __LINE__ __attribute__((cleanup(ext_executeCleanupBlock), unused)) = ^

/*** implementation details follow ***/
typedef void (^ext_cleanupBlock_t)();

void ext_executeCleanupBlock (ext_cleanupBlock_t *block);
