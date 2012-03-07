The Extended Objective-C library extends the dynamism of the Objective-C programming language to support additional patterns present in other dynamic programming languages (including those that are not necessarily object-oriented).

libextobjc is meant to be very modular – most of its classes and modules can be used with no more than one or two dependencies.

# Features

libextobjc currently includes the following features:

 * **Safe categories**, using the EXTSafeCategory module, for adding methods to a class without overwriting anything already there (identifying conflicts for you).
 * **Concrete protocols**, using the EXTConcreteProtocol module, for providing default implementations of the methods in a protocol.
 * **Scope-based resource cleanup**, using the EXTScope module, for automatically cleaning up manually-allocated memory, file handles, locks, etc., at the end of a scope.
 * **EXTNil, which is like `NSNull`, but behaves much more closely to actual `nil`** (i.e., doesn't crash when sent unrecognized messages).
 * **EXTBlockTarget, which extends the target-action mechanism with support for blocks**.
 * Aspect-oriented programming, using the EXTAspect module. This feature [requires libffi](#Requirements), and so is not enabled by default.
 * Block-based coroutines, using the EXTCoroutine module.
 * Final methods – methods which cannot be overridden – using the EXTFinalMethod module.
 * Private methods – methods which cannot be invoked by other classes – using the EXTPrivateMethod module.
 * The EXTDispatchObject class, which forwards messages to all objects in a given array.
 * The EXTMaybe class, which behaves like `NSError` _and_ `nil`, making it safe for use as an erroneous return value.
 * The EXTMultiObject class, which behaves like all of the objects in a given array (forwarding to the first one that responds to each message).
 * Primitive mixins, using the EXTMixin module.
 * Protocol categories, using the EXTProtocolCategory module, for adding methods to every class that implements a given protocol.
 * Convenience functions to install blocks as methods, using the EXTBlockMethod module.
 * Lots of extensions and additional functionality built on top of `<objc/runtime.h>`, including extremely customizable method injection, reflection upon object properties, and various functions to extend class hierarchy checks and method lookups.

Some of these are just proofs of concept, and not necessarily recommended for production code. Others are quite valuable, and make Objective-C safer and/or more flexible. Check out the headers for more information.

# License

This library is public domain, and can be incorporated for free and without attribution for any use. Submodules and dependencies may have different licenses.

# Requirements

* The latest version of [libffi](https://github.com/atgreen/libffi) is needed to enable EXTAspect, but is not required for the rest of the project. 
    * For iOS, [a compatible version of libffi](https://github.com/jspahrsummers/libffi) is included as a submodule, and is built and linked automatically.
    * For Mac OS X, libffi should be installed with [Homebrew](https://github.com/atgreen/homebrew).

See `Modules/EXTAspect.h` for more information and instructions on setting up the project to use libffi.
