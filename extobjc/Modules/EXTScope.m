//
//  EXTScope.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-05-04.
//  Released into the public domain.
//

#import "EXTScope.h"

void ext_executeCleanupBlock (ext_cleanupBlock_t *block) {
	(*block)();
}

void ext_releaseScopeObject (id *objPtr) {
	[*objPtr release];
}

