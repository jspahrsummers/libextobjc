//
//  EXTScope.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-05-04.
//  Copyright (C) 2012 Justin Spahr-Summers.
//  Released under the MIT license.
//

#import "EXTScope.h"
#import <libkern/OSAtomic.h>
#import <objc/runtime.h>

static NSMutableSet *swizzledClasses() {
    static dispatch_once_t onceToken;
    static NSMutableSet *swizzledClasses = nil;
    dispatch_once(&onceToken, ^{
        swizzledClasses = [[NSMutableSet alloc] init];
    });
    
    return swizzledClasses;
}

static OSSpinLock garbageReferencesLock;
static CFMutableSetRef garbageReferences() {
    static dispatch_once_t onceToken;
    static CFMutableSetRef garbageReferences = NULL;
    dispatch_once(&onceToken, ^{
        garbageReferences = CFSetCreateMutable(NULL, 0, NULL);
    });
    return garbageReferences;
}

void ext_executeCleanupBlock (__strong ext_cleanupBlock_t *block) {
    (*block)();
}

void ext_addGarbageGuard (__strong NSObject *target) {
    void (^swizzle)(Class) = ^(Class classToSwizzle){
        NSString *className = NSStringFromClass(classToSwizzle);
        if ([swizzledClasses() containsObject:className]) return;
        
        SEL deallocSelector = sel_registerName("dealloc");
        
        Method deallocMethod = class_getInstanceMethod(classToSwizzle, deallocSelector);
        void (*originalDealloc)(id, SEL) = (__typeof__(originalDealloc))method_getImplementation(deallocMethod);
        
        id newDealloc = ^(__unsafe_unretained NSObject *self) {
            OSSpinLockLock(&garbageReferencesLock);
            CFSetAddValue(garbageReferences(), (__bridge const void *)(self));
            OSSpinLockUnlock(&garbageReferencesLock);
            originalDealloc(self, deallocSelector);
            OSSpinLockLock(&garbageReferencesLock);
            CFSetRemoveValue(garbageReferences(), (__bridge const void *)(self));
            OSSpinLockUnlock(&garbageReferencesLock);
        };
        
        class_replaceMethod(classToSwizzle, deallocSelector, imp_implementationWithBlock(newDealloc), method_getTypeEncoding(deallocMethod));
        
        [swizzledClasses() addObject:className];
    };
    
    @synchronized (swizzledClasses()) {
        swizzle(target.class);
    }
}

void ext_checkGarbageGuard (__unsafe_unretained NSObject *target) {
    Boolean targetIsGarbage = false;
    OSSpinLockLock(&garbageReferencesLock);
    targetIsGarbage = CFSetContainsValue(garbageReferences(), (__bridge const void *)(target));
    OSSpinLockUnlock(&garbageReferencesLock);
    if (targetIsGarbage) [NSException raise:NSInternalInconsistencyException format:@"Attempted to strongify garbage reference."];
}
