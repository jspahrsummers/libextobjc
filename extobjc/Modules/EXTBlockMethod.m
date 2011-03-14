//
//  EXTBlockMethod.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-03-11.
//  Released into the public domain.
//

#import "EXTBlockMethod.h"

BOOL ext_addBlockMethod (Class aClass, SEL name, id block, const char *types) {
	return class_addMethod(
		aClass,
		name,
		ext_blockImplementation(block),
		types
	);
}

IMP ext_blockImplementation (id block) {
	IMP impl = NULL;

	// the function pointer for a block is at +12 bytes on iOS (32 bit) and +16
	// bytes on OS X (64 bit), so we assume a constant of +8 incremented by the
	// size of a pointer
	impl = *(IMP *)((char *)block + 8 + sizeof(void *));

	return impl;
}

void ext_replaceBlockMethod (Class aClass, SEL name, id block, const char *types) {
	class_replaceMethod(
		aClass,
		name,
		ext_blockImplementation(block),
		types
	);
}

