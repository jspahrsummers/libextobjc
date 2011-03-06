//
//  EXTPrivateMethod.h
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-03-02.
//  Released into the public domain.
//

#import <objc/runtime.h>
#import <stdio.h>
#import "metamacros.h"

#define private(CLASS) \
	protocol ext_ ## CLASS ## _PrivateMethods

#define endprivate(CLASS) \
	end \
	\
	@interface NSObject (CLASS ## _PrivateMethodsProtocol) <ext_ ## CLASS ## _PrivateMethods> \
	@end \
	\
	__attribute__((constructor)) \
	static void ext_ ## CLASS ## _injectPrivateMethods (void) { \
		Class targetClass = objc_getClass(# CLASS); \
		Protocol *protocol = @protocol(ext_ ## CLASS ## _PrivateMethods); \
		\
		if (!ext_makeProtocolMethodsPrivate(targetClass, protocol)) { \
			fprintf(stderr, "ERROR: Could not add private methods for class %s\n", # CLASS); \
		} \
	}

#define privateSelf super

/*** implementation details follow ***/
#define ext_privateMethodProtocolName(CLASS) \
	

BOOL ext_makeProtocolMethodsPrivate (Class targetClass, Protocol *protocol);
