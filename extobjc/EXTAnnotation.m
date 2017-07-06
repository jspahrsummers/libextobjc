//
//  EXTAnnotation.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 27.06.12.
//  Copyright (C) 2012 Justin Spahr-Summers.
//  Released under the MIT license.
//

#import "EXTAnnotation.h"
#import "EXTScope.h"
#import <objc/runtime.h>

static void * const ext_classAnnotationKey = "ext_classAnnotation";

BOOL ext_applyAnnotationAfterMarkerProperty (Class targetClass, id annotation, const char *markerPropertyName) {
    unsigned propertyCount = 0;
    objc_property_t *properties = class_copyPropertyList(targetClass, &propertyCount);
    if (!properties)
        return NO;

    @onExit {
        free(properties);
    };

    // look for the marker, which should be before the actual property we're
    // annotating
    for (unsigned i = 0; i < propertyCount - 1; ++i) {
        objc_property_t markerProperty = properties[i];
        if (strcmp(property_getName(markerProperty), markerPropertyName) == 0) {
            objc_property_t realProperty = properties[i + 1];
            objc_setAssociatedObject(targetClass, realProperty, annotation, OBJC_ASSOCIATION_COPY);
            return YES;
        }
    }

    return NO;
}

BOOL ext_applyAnnotationToClass (Class targetClass, id annotation) {
    objc_setAssociatedObject(targetClass, ext_classAnnotationKey, annotation, OBJC_ASSOCIATION_COPY);
    return YES;
}

NSDictionary *ext_getClassAnnotation (Class annotatedClass) {
    return objc_getAssociatedObject(annotatedClass, ext_classAnnotationKey);
}

NSDictionary *ext_getPropertyAnnotation (Class annotatedClass, NSString *propertyName) {
    objc_property_t property = class_getProperty(annotatedClass, propertyName.UTF8String);
    if (!property)
        return nil;

    return objc_getAssociatedObject(annotatedClass, property);
}
