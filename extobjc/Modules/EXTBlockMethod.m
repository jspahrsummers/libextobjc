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
	return (IMP)(*((void**)block + 2));
}
