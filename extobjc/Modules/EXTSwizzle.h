/*
 *  EXTSwizzle.h
 *  libextobjc
 *
 *  Created by Justin Spahr-Summers on 04.08.10.
 *  Released into the public domain.
 */

#import <objc/runtime.h>
#import <stdio.h>
#import "metamacros.h"

/**
 * Replaces an instance method on \a CLASS, saving it under a new name.
 * \a ORIGINAL specifies a selector name to replace with the implementation from
 * \a NEW. Once replaced, the original implementation will be stored as selector
 * \a RENAME. If \a RENAME is already in use, it will not be overwritten and the
 * original method implementation will be lost!
 *
 * @code
 * @implementation UIView (BetterDescription)
 * - (NSString *)betterDescription {
 *     return [@"This description is better than " stringByAppendingString:
 *         [self oldDescription]];
 * }
 *
 * + (void)load {
 *     EXT_SWIZZLE_INSTANCE_METHODS(
 *         UIView,            // class
 *         description,       // original method name
 *         betterDescription, // method to replace it with
 *         oldDescription     // new name for the original
 *     );
 * }
 * @end
 * @endcode
 *
 * @note This may not work as intended for class clusters.
 *
 * @warning This macro will allow you to swap methods with different argument
 * and return types, but doing so could cause crashes, memory corruption, or
 * other erratic behavior. Note that the compiler will not warn you if you do
 * this by mistake!
 */
#define EXT_SWIZZLE_INSTANCE_METHODS(CLASS, ORIGINAL, NEW, RENAME) \
	do { \
		Class cls_ = objc_getClass(metamacro_stringify(CLASS)); \
		if (!cls_) { \
			fprintf(stderr, "ERROR: no class %s exists\n", \
				metamacro_stringify(CLASS) \
			); \
			break; \
		} \
		\
		Method orig_ = class_getInstanceMethod(cls_, @selector(ORIGINAL)); \
		if (!orig_) { \
			fprintf(stderr, "ERROR: class %s and superclasses do not contain an instance method for selector %s\n", \
				metamacro_stringify(CLASS), \
				metamacro_stringify(ORIGINAL) \
			); \
			break; \
		} \
		\
		Method new_ = class_getInstanceMethod(cls_, @selector(NEW)); \
		if (!new_) { \
			fprintf(stderr, "ERROR: class %s and superclasses do not contain an instance method for selector %s\n", \
				metamacro_stringify(CLASS), \
				metamacro_stringify(NEW) \
			); \
			break; \
		} \
		\
		IMP origImpl_ = method_getImplementation(orig_); \
		if (!class_addMethod(cls_, @selector(RENAME), origImpl_, method_getTypeEncoding(orig_))) { \
			fprintf(stderr, "ERROR: could not add instance method %s on %s\n", \
				metamacro_stringify(RENAME), \
				metamacro_stringify(CLASS) \
			); \
			break; \
		} \
		\
		IMP newImpl_ = method_getImplementation(new_); \
		class_replaceMethod(cls_, @selector(ORIGINAL), newImpl_, method_getTypeEncoding(new_)); \
	} while (0)

/**
 * Replaces a class method on \a CLASS, saving it under a new name. \a ORIGINAL 
 * specifies a selector name to replace with the implementation from \a NEW.
 * Once replaced, the original implementation will be stored as selector
 * \a RENAME. If \a RENAME is already in use, it will not be overwritten and the
 * original method implementation will be lost!
 *
 * @sa EXT_SWIZZLE_INSTANCE_METHODS
 *
 * @note This may not work as intended for class clusters.
 *
 * @warning This macro will allow you to swap methods with different argument
 * and return types, but doing so could cause crashes, memory corruption, or
 * other erratic behavior. Note that the compiler will not warn you if you do
 * this by mistake!
 */
#define EXT_SWIZZLE_CLASS_METHODS(CLASS, ORIGINAL, NEW, RENAME) \
	do { \
		Class cls_ = objc_getClass(metamacro_stringify(CLASS)); \
		if (!cls_) { \
			fprintf(stderr, "ERROR: no class %s exists\n", \
				metamacro_stringify(CLASS) \
			); \
			break; \
		} \
		\
		Class meta_ = object_getClass(cls_); \
		Method orig_ = class_getClassMethod(cls_, @selector(ORIGINAL)); \
		if (!orig_) { \
			fprintf(stderr, "ERROR: class %s and superclasses do not contain a class method for selector %s\n", \
				metamacro_stringify(CLASS), \
				metamacro_stringify(ORIGINAL) \
			); \
			break; \
		} \
		\
		Method new_ = class_getClassMethod(cls_, @selector(NEW)); \
		if (!new_) { \
			fprintf(stderr, "ERROR: class %s and superclasses do not contain a class method for selector %s\n", \
				metamacro_stringify(CLASS), \
				metamacro_stringify(NEW) \
			); \
			break; \
		} \
		\
		IMP origImpl_ = method_getImplementation(orig_); \
		if (!class_addMethod(meta_, @selector(RENAME), origImpl_, \
			method_getTypeEncoding(orig_))) { \
			fprintf(stderr, "ERROR: could not add class method %s on %s\n", \
				metamacro_stringify(RENAME), \
				metamacro_stringify(CLASS) \
			); \
			break; \
		} \
		\
		IMP newImpl_ = method_getImplementation(new_); \
		class_replaceMethod(meta_, @selector(ORIGINAL), newImpl_, method_getTypeEncoding(new_)); \
	} while (0)
