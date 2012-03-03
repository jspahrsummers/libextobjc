The Extended Objective-C library extends the dynamism of the Objective-C programming language to support additional patterns present in other dynamic programming languages (including those that are not necessarily object-oriented).

Current features include concrete protocols, safe categories, private methods, and conveniences for interacting with the runtime, among others.

# License

This library is public domain, and can be incorporated for free and without attribution for any use. Submodules and dependencies may have different licenses.

# Requirements

* The latest version of [libffi](https://github.com/atgreen/libffi) is needed to enable EXTAspect, but is not required for the rest of the project. 
    * For iOS, [a compatible version of libffi](https://github.com/jspahrsummers/libffi) is included as a submodule, and is built and linked automatically.
    * For Mac OS X, libffi should be installed with [Homebrew](https://github.com/atgreen/homebrew).

See `Modules/EXTAspect.h` for more information and instructions on setting up the project to use libffi.
