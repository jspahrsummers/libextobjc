The Extended Objective-C library extends the dynamism of the Objective-C programming language to support additional patterns present in other dynamic programming languages (including those that are not necessarily object-oriented).

libextobjc is meant to be very modular – most of its classes and modules can be used with no more than one or two dependencies.

Please feel free to open issues for feature requests or ideas for language extensions (even if you have no idea how they'd work)!

# Features

libextobjc currently includes the following features:

 * **Safe categories**, using EXTSafeCategory, for adding methods to a class without overwriting anything already there (identifying conflicts for you).
 * **Concrete protocols**, using EXTConcreteProtocol, for providing default implementations of the methods in a protocol.
 * **Simpler and safer key paths**, using EXTKeyPathCoding, which automatically checks key paths at compile-time.
 * **Compile-time checking of selectors** to ensure that an object declares a given selector, using EXTSelectorChecking.
 * **Easier use of weak variables in blocks**, using `@weakify`, `@unsafeify`, and `@strongify` from the EXTScope module.
 * **Safer private methods**, using EXTPrivateMethod, for declaring methods on a class, and getting notified if they conflict with other existing methods.
 * **Scope-based resource cleanup**, using `@onExit` in the EXTScope module, for automatically cleaning up manually-allocated memory, file handles, locks, etc., at the end of a scope.
 * **EXTNil, which is like `NSNull`, but behaves much more closely to actual `nil`** (i.e., doesn't crash when sent unrecognized messages).
 * **Synthesized properties for categories**, using EXTSynthesize.
 * **Algebraic data types** generated completely at compile-time, defined using EXTADT.
 * EXTBlockTarget, which extends the target-action mechanism with support for blocks.
 * EXTTuple, for multiple return values and assignment.
 * EXTPassthrough, to automatically implement methods that simply invoke the same method on another object.
 * Better variadic arguments, with support for packaging the arguments up as an array, using EXTVarargs.
 * Aspect-oriented programming, using EXTAspect.
 * Block-based coroutines, using EXTCoroutine.
 * Multimethods – methods which overload based on argument type – using EXTMultimethod.
 * Key-value annotations on properties, using EXTAnnotation.
 * Final methods – methods which cannot be overridden – using EXTFinalMethod.
 * EXTDispatchObject, which forwards messages to all objects in a given array.
 * EXTMaybe, which behaves like `NSError` _and_ `nil`, making it safe for use as an erroneous return value.
 * EXTMultiObject, which behaves like all of the objects in a given array (forwarding to the first one that responds to each message).
 * Primitive mixins, using EXTMixin.
 * Protocol categories, using EXTProtocolCategory, for adding methods to every class that implements a given protocol.
 * Convenience functions to install blocks as methods, using EXTBlockMethod.
 * Lots of extensions and additional functionality built on top of `<objc/runtime.h>`, including extremely customizable method injection, reflection upon object properties, and various functions to extend class hierarchy checks and method lookups.

Some of these are just proofs of concept, and not necessarily recommended for production code. Others (mainly those bolded in the list above) are quite valuable, and make Objective-C safer and/or more flexible. Check out the headers for more information.

# License

Released under the MIT License. See the
[LICENSE](https://github.com/jspahrsummers/libextobjc/blob/master/LICENSE.md)
file for more information.

# Requirements

[libffi](https://github.com/jspahrsummers/libffi) is used for EXTAspect, but is not required for the other modules of the project. In order for the unit tests to build and pass, libffi must be retrieved using `git submodule update --init` after cloning the repository.
