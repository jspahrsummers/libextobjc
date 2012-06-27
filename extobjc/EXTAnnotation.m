//
//  EXTAnnotation.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 27.06.12.
//  Released into the public domain.
//

#import "EXTAnnotation.h"
#import "EXTScope.h"
#import <objc/runtime.h>

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

NSDictionary *ext_getAnnotation (Class annotatedClass, NSString *propertyName) {
    objc_property_t property = class_getProperty(annotatedClass, propertyName.UTF8String);
    if (!property)
        return nil;

    return objc_getAssociatedObject(annotatedClass, property);
}
