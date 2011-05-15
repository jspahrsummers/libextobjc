//
//  EXTSynthesize.h
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-05-12.
//  Released into the public domain.
//

#import "EXTRuntimeExtensions.h"

#define synthesizeall \
	protocol NSObject; \
	\
	+ (void)load { \
		ext_synthesizePropertiesForClass(self); \
	}

/*** implementation details follow ***/
void ext_synthesizePropertiesForClass (Class cls);
