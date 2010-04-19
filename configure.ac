AC_PREREQ(2.65)
AC_INIT([extc], [0.1], [Justin.SpahrSummers@gmail.com])
AM_INIT_AUTOMAKE([dist-bzip2])
AC_CONFIG_MACRO_DIR([m4])
AC_CONFIG_SRCDIR([include/extc.h])
AC_CONFIG_HEADERS([config.h])

AC_PROG_CC
AC_PROG_CC_C99
AM_PROG_CC_C_O
AC_PROG_INSTALL
AC_PROG_LIBTOOL

AC_HEADER_STDBOOL
AC_CHECK_HEADERS([assert.h setjmp.h stdarg.h stddef.h], [], AC_MSG_ERROR([libextc requires all the headers defined as standard in C99]))

# for benchmarks in module tests, not libextc proper
AC_CHECK_HEADERS_ONCE([sys/time.h])
AC_CHECK_FUNCS_ONCE([gettimeofday])

AC_TYPE_SIZE_T
AC_C_RESTRICT

AC_CONFIG_FILES([Makefile include/Makefile src/Makefile tests/Makefile])
AC_OUTPUT
