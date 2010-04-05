check_PROGRAMS		= test
TESTS 				= $(check_PROGRAMS)

test_SOURCES 		= exceptions_test.c main.c vector_test.c
test_CPPFLAGS       = -pedantic -Wall -Wextra -I../include -I$(pkgincludedir)
test_LDADD 			= ../src/libextc.la
