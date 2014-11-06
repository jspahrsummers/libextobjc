//
//  EXTSynthesize.h
//  extobjc
//
//  Created by Justin Spahr-Summers on 2012-09-04.
//  Copyright (C) 2012 Justin Spahr-Summers.
//  Released under the MIT license.
//

#import "EXTRuntimeExtensions.h"
#import <objc/runtime.h>

/**
 * \@synthesizeAssociation synthesizes a property for a class using associated
 * objects. This is primarily useful for adding properties to a class within
 * a category.
 *
 * PROPERTY must have been declared with \@property in the interface of the
 * specified class (or a category upon it), and must be of object type.
 */
#define synthesizeAssociation(CLASS, PROPERTY) \
	dynamic PROPERTY; \
	\
	static void *ext_uniqueKey_ ## CLASS ## _ ## PROPERTY = &ext_uniqueKey_ ## CLASS ## _ ## PROPERTY; \
	\
	__attribute__((constructor)) \
	static void ext_ ## CLASS ## _ ## PROPERTY ## _synthesize (void) { \
		Class cls = objc_getClass(# CLASS); \
		objc_property_t property = class_getProperty(cls, # PROPERTY); \
		NSCAssert(property, @"Could not find property %s on class %@", # PROPERTY, cls); \
		\
		ext_propertyAttributes *attributes = ext_copyPropertyAttributes(property); \
		if (!attributes) { \
			NSLog(@"*** Could not copy property attributes for %@.%s", cls, # PROPERTY); \
			return; \
		} \
		\
		NSCAssert(!attributes->weak, @"@synthesizeAssociation does not support weak properties (%@.%s)", cls, # PROPERTY); \
		\
		objc_AssociationPolicy policy = OBJC_ASSOCIATION_ASSIGN; \
		switch (attributes->memoryManagementPolicy) { \
			case ext_propertyMemoryManagementPolicyRetain: \
				policy = attributes->nonatomic ? OBJC_ASSOCIATION_RETAIN_NONATOMIC : OBJC_ASSOCIATION_RETAIN; \
				break; \
			\
			case ext_propertyMemoryManagementPolicyCopy: \
				policy = attributes->nonatomic ? OBJC_ASSOCIATION_COPY_NONATOMIC : OBJC_ASSOCIATION_COPY; \
				break; \
			\
			case ext_propertyMemoryManagementPolicyAssign: \
				break; \
			\
			default: \
				NSCAssert(NO, @"Unrecognized property memory management policy %i", (int)attributes->memoryManagementPolicy); \
		} \
		\
		id getter = ^(id self){ \
			return objc_getAssociatedObject(self, ext_uniqueKey_ ## CLASS ## _ ## PROPERTY); \
		}; \
		\
		id setter = ^(id self, id value){ \
			objc_setAssociatedObject(self, ext_uniqueKey_ ## CLASS ## _ ## PROPERTY, value, policy); \
		}; \
		\
		if (!class_addMethod(cls, attributes->getter, imp_implementationWithBlock(getter), "@@:")) { \
			NSCAssert(NO, @"Could not add getter %s for property %@.%s", sel_getName(attributes->getter), cls, # PROPERTY); \
		} \
		\
		if (!class_addMethod(cls, attributes->setter, imp_implementationWithBlock(setter), "v@:@")) { \
			NSCAssert(NO, @"Could not add setter %s for property %@.%s", sel_getName(attributes->setter), cls, # PROPERTY); \
		} \
		\
		free(attributes); \
	}
