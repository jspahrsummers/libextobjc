//
//  EXTCoroutine.h
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-05-22.
//  Released into the public domain.
//

#import "metamacros.h"

#define coroutine(...) \
	^{ \
		__block unsigned long ext_coroutine_line_ = 0; \
		\
		return [[ \
			^(__VA_ARGS__) coroutine_body
	
#define coroutine_body(STATEMENT) \
			{ \
				for (;; ext_coroutine_line_ = 0) \
					switch (ext_coroutine_line_) \
						default: \
							STATEMENT \
			} \
		copy] autorelease]; \
	}()

#define yield \
	if ((ext_coroutine_line_ = __LINE__) == 0) \
		case __LINE__: \
			; \
	else \
		return

