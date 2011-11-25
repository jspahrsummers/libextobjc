The ExtendedObjC library extends the dynamism of the Objective-C programming language to support additional patterns present in other dynamic programming languages (including those that are not necessarily object-oriented).

Current features include concrete protocols, safe categories, private methods, and conveniences for interacting with the runtime, among others.

# License

This library is public domain, and can be incorporated for free and without attribution for any use. Submodules and dependencies may have different licenses.

# Requirements

* The latest version of [libffi](https://github.com/atgreen/libffi) is needed to compile the whole project. Certain modules may not require libffi, and can therefore be used independently if pulled out of the Xcode project.
    * For iOS, [a compatible version of libffi](https://github.com/jspahrsummers/libffi) is included as a submodule, and is built and linked automatically.
    * For Mac OS X, libffi should be installed with [Homebrew](https://github.com/jspahrsummers/homebrew).
