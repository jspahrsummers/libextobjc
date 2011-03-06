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

/**
 * Declares private methods for \a CLASS. Any methods declared inside this block
 * will not be visible to or invokable by other classes, and will not conflict
 * with private or public methods by the same name declared in any subclasses.
 *
 * Private method declarations must be followed by \c @endprivate. The methods
 * themselves must be invoked using #privateSelf.
 *
 * @todo Private methods by the same name currently cannot exist in classes that
 * are immediate descendants of the same superclass.
 *
 * @warning Private methods will not be available at the point of \c +load, and
 * possibly not even by \c +initialize.
 */
#define private(CLASS) \
	protocol ext_ ## CLASS ## _PrivateMethods; \
	@protocol ext_ ## CLASS ## _FakeProtocol <ext_ ## CLASS ## _PrivateMethods> \
	@end \
	\
	@interface NSObject (CLASS ## _PrivateMethodsProtocol) <ext_ ## CLASS ## _FakeProtocol> \
	@end \
	\
	extern Class ext_privateMethodsClass_; \
	extern Protocol *ext_privateMethodsFakeProtocol_; \
	\
	__attribute__((constructor)) \
	static void ext_ ## CLASS ## _preparePrivateMethods (void) { \
		ext_privateMethodsClass_ = objc_getClass(# CLASS); \
		ext_privateMethodsFakeProtocol_ = @protocol(ext_ ## CLASS ## _FakeProtocol); \
	} \
	\
	@protocol ext_ ## CLASS ## _PrivateMethods

/**
 * Ends a set of private method declarations. This must be used instead of \c
 * @end.
 */
#define endprivate \
	end \
	\
	__attribute__((constructor)) \
	static void metamacro_concat(ext_injectPrivateMethods_, __LINE__) (void) { \
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

/**
 * Required to invoke a private method. If this keyword is not used, method
 * lookup may fail.
 */
#define privateSelf super

/*** implementation details follow ***/
BOOL ext_makeProtocolMethodsPrivate (Class targetClass, Protocol *protocol);
