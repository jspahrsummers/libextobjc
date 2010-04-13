check_PROGRAMS		= test
TESTS 				= $(check_PROGRAMS)

test_SOURCES 		= algorithm_test.c enum_test.c exception_test.c main.c memory_test.c refcounted_test.c scope_test.c vector_test.c
test_CPPFLAGS       = -pedantic -Wall -Wextra -I../include -I$(pkgincludedir)
test_LDADD 			= ../src/libextc.la
