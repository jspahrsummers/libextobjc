//
//  EXTPrivateMethod.h
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-03-02.
//  Released into the public domain.
//

#import <objc/runtime.h>
#import <stdio.h>
#import <stdlib.h>
#import "metamacros.h"

#define private(CLASS) \
	protocol ext_ ## CLASS ## _PrivateMethods; \
	@protocol ext_ ## CLASS ## _FakeProtocol <ext_ ## CLASS ## _PrivateMethods> \
	@end \
	\
	@interface NSObject (CLASS ## _PrivateMethodsProtocol) <ext_ ## CLASS ## _FakeProtocol> \
	@end \
	\
	static Class ext_privateMethodsClass_ = nil; \
	static Protocol *ext_privateMethodsFakeProtocol_ = NULL; \
	\
	__attribute__((constructor)) \
	static void ext_injectPrivateMethods1 (void) { \
		ext_privateMethodsClass_ = objc_getClass(# CLASS); \
		ext_privateMethodsFakeProtocol_ = @protocol(ext_ ## CLASS ## _FakeProtocol); \
	} \
	\
	@protocol ext_ ## CLASS ## _PrivateMethods

#define endprivate \
	end \
	\
	__attribute__((constructor)) \
	static void ext_injectPrivateMethods (void) { \
		Class targetClass = ext_privateMethodsClass_; \
		\
		unsigned listCount = 0; \
		Protocol **protocolList = protocol_copyProtocolList(ext_privateMethodsFakeProtocol_, &listCount); \
		\
		Protocol *privateMethodsProtocol = protocolList[0]; \
		free(protocolList); \
		\
		if (!ext_makeProtocolMethodsPrivate(targetClass, privateMethodsProtocol)) { \
			fprintf(stderr, "ERROR: Could not add private methods for class %s\n", class_getName(targetClass)); \
		} \
	}

#define privateSelf super

/*** implementation details follow ***/
BOOL ext_makeProtocolMethodsPrivate (Class targetClass, Protocol *protocol);
