//
//  EXTSynthesize.h
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-05-12.
//  Released into the public domain.
//

#import "EXTRuntimeExtensions.h"

/**
 * @warning Not yet finished. Do not use!
 */
#define synthesizeall \
	protocol NSObject; \
	\
	+ (void)load { \
		ext_synthesizePropertiesForClass(self); \
	}

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

/*** implementation details follow ***/
void ext_synthesizePropertiesForClass (Class cls);
