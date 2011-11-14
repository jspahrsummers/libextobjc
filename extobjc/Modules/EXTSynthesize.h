//
//  EXTSynthesize.h
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-05-12.
//  Released into the public domain.
//

#import "EXTRuntimeExtensions.h"

/**
 * \@synthesizeall will synthesize on the current class all properties that are
 * not \c @dynamic, if any. Existing getters and setters are left untouched.
 *
 * @note This defines a \c +load method for your class. If you need to define
 * \c +load, consider using \c +initialize or a manual call to
 * ext_synthesizePropertiesForClass() instead.
 */
#define synthesizeall \
	protocol NSObject; \
	\
	+ (void)load { \
		ext_synthesizePropertiesForClass(self); \
	}

/**
 * Overrides the \c allocWithZone: method of of \a aClass to return objects that
 * have extra space for indexed instance variables. If this is the first use of
 * ext_addIndexedIvar() on \a aClass or any of its superclasses, the extra space
 * will be exactly \a ivarSize bytes in length. If ext_addIndexedIvar() has been
 * used on \a aClass or one of its superclasses before, the extra space will be
 * at least \a ivarSize bytes in length.
 *
 * Returns the offset (in bytes) of the newly-reserved indexed ivar. The offset
 * is guaranteed to be aligned to a multiple of \a ivarAlignment. Add the offset
 * to the pointer returned by \c object_getIndexedIvars() to get to the new
 * ivar.
 *
 * @warning This will only affect instances of \a aClass (or its subclasses)
 * allocated \e after this function is called. Instances allocated prior will
 * not have this extra storage.
 */
size_t ext_addIndexedIvar (Class aClass, size_t ivarSize, size_t ivarAlignment);

/**
 * Synthesizes a property on \a aClass according to the given attributes. This
 * may add indexed ivars to \a aClass if additional storage is necessary.
 *
 * @note This respects \c @dynamic properties, and will not attempt to
 * synthesize them. It also leaves existing getters and setters untouched.
 *
 * @warning This will only affect instances of \a aClass (or its subclasses)
 * allocated \e after this function is called. Instances allocated prior may not
 * have this property fully synthesized, and trying to use the getter or setter
 * will result in undefined behavior.
 */
void ext_synthesizeProperty (Class aClass, const ext_propertyAttributes * restrict attributes);

/**
 * Synthesizes all properties on \a cls according to the semantics of
 * ext_synthesizeProperty().
 */
void ext_synthesizePropertiesForClass (Class cls);
