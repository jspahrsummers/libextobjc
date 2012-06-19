//
//  EXTKeyPathCoding.h
//  extobjc
//
//  Created by Justin Spahr-Summers on 19.06.12.
//  Released into the public domain.
//

#import <Foundation/Foundation.h>
#import "metamacros.h"

#define keypath(PATH) \
    (((void)(NO && ((void)PATH, NO)), strchr(# PATH, '.') + 1))
