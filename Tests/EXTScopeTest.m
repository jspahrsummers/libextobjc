//
//  EXTScopeTest.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-05-04.
//  Copyright (C) 2012 Justin Spahr-Summers.
//  Released under the MIT license.
//

#import "EXTScopeTest.h"

@interface EXTScopeTest ()
- (void)nestedAppend:(NSMutableString *)str;
- (void)nestedThrowingAppend:(NSMutableString *)str;
@end

@implementation EXTScopeTest

- (void)testOnExit {
    NSMutableString *str = [@"foo" mutableCopy];

    {
        @onExit {
            [str appendString:@"bar"];
        };
    }

    STAssertEqualObjects(str, @"foobar", @"'bar' should've been appended to 'foo' at the end of the previous scope");

    __block unsigned executed = 0;

    for (unsigned i = 1;i <= 3;++i) {
        @onExit {
            executed += i;
        };
    }

    STAssertEquals(executed, 6U, @"onExit blocks should be executed on loop iterations");

    executed = 0;
    for (unsigned i = 1;i <= 4;++i) {
        @onExit {
            executed += i;
        };

        if (i > 3)
            break;

        if (i % 2 == 0)
            continue;
    }

    STAssertEquals(executed, 10U, @"onExit blocks should be executed even when break or continue is used");

    executed = 0;
    {
        {
            @onExit {
                ++executed;
            };

            goto skipStuff;
            executed = 10;
        }
        
        skipStuff:
            ++executed;
    }

    STAssertEquals(executed, 2U, @"onExit blocks should be executed even when goto is used");
    
    str = [@"foo" mutableCopy];
    {
        @onExit {
            [str appendString:@"baz"];
        };
        [str appendString:@"bar"];
        STAssertEqualObjects(str, @"foobar", @"onExit block should not be executed before the scope ends");
    }

    str = [@"foo" mutableCopy];
    [self nestedAppend:str];

    STAssertEqualObjects(str, @"foobar", @"'bar' should've been appended to 'foo' at the end of a called method that exited early");
}

- (void)nestedAppend:(NSMutableString *)str {
    @onExit {
        [str appendString:@"bar"];
    };

    if ([str isEqualToString:@"foo"])
        return;
    
    [str appendString:@"buzz"];
}

- (void)nestedThrowingAppend:(NSMutableString *)str {
    @onExit {
        [str appendString:@"bar"];
    };

    if ([str isEqualToString:@"foo"])
        [NSException raise:@"EXTScopeTestException" format:@"test exception for @onExit cleanup in method"];
    
    [str appendString:@"buzz"];
}

- (void)testLexicalOrdering {
    __block unsigned lastBlockEntered = 0;

    {
        @onExit {
            STAssertEquals(lastBlockEntered, 2U, @"lexical ordering of @onExit blocks is not correct!");

            lastBlockEntered = 1;
        };

        @onExit {
            STAssertEquals(lastBlockEntered, 3U, @"lexical ordering of @onExit blocks is not correct!");

            lastBlockEntered = 2;
        };

        @onExit {
            STAssertEquals(lastBlockEntered, 4U, @"lexical ordering of @onExit blocks is not correct!");

            lastBlockEntered = 3;
        };

        @onExit {
            STAssertEquals(lastBlockEntered, 0U, @"lexical ordering of @onExit blocks is not correct!");

            lastBlockEntered = 4;
        };
    }

    STAssertEquals(lastBlockEntered, 1U, @"lexical ordering of @onExit blocks is not correct, or cleanup blocks did not execute at all!");
}

- (void)testExceptionCleanup {
    __block BOOL cleanupBlockRun = NO;

    @try {
        @onExit {
            cleanupBlockRun = YES;
        };

        [NSException raise:@"EXTScopeTestException" format:@"test exception for @onExit cleanup in @try"];
    } @catch (NSException *exception) {
        STAssertEqualObjects([exception name], @"EXTScopeTestException", @"unexpected exception %@ thrown");
    } @finally {
        STAssertTrue(cleanupBlockRun, @"@onExit block was not run when an exception was thrown");
    }

    STAssertTrue(cleanupBlockRun, @"@onExit block was not run when an exception was thrown");

    NSMutableString *str = [@"foo" mutableCopy];

    @try {
        [self nestedThrowingAppend:str];
    } @catch (NSException *exception) {
        STAssertEqualObjects([exception name], @"EXTScopeTestException", @"unexpected exception %@ thrown");
    }

    STAssertEqualObjects(str, @"foobar", @"'bar' should've been appended to 'foo' at the end of a called method that threw an exception");
}

- (void)testWeakifyUnsafeifyStrongify {
    void (^verifyMemoryManagement)(void);

    @autoreleasepool {
        NSString *foo __attribute__((objc_precise_lifetime)) = [@"foo" mutableCopy];
        NSString *bar __attribute__((objc_precise_lifetime)) = [@"bar" mutableCopy];

        void *fooPtr = &foo;
        void *barPtr = &bar;

        @weakify(foo);
        @unsafeify(bar);

        BOOL (^matchesFooOrBar)(NSString *) = ^ BOOL (NSString *str){
            @strongify(bar, foo);

            STAssertEqualObjects(foo, @"foo", @"");
            STAssertEqualObjects(bar, @"bar", @"");

            STAssertTrue(fooPtr != &foo, @"Address of 'foo' within block should be different from its address outside the block");
            STAssertTrue(barPtr != &bar, @"Address of 'bar' within block should be different from its address outside the block");

            return [foo isEqual:str] || [bar isEqual:str];
        };

        STAssertTrue(matchesFooOrBar(@"foo"), @"");
        STAssertTrue(matchesFooOrBar(@"bar"), @"");
        STAssertFalse(matchesFooOrBar(@"buzz"), @"");

        verifyMemoryManagement = [^{
            // Can only strongify the weak reference without issue.
            @strongify(foo);
            STAssertNil(foo, @"");
        } copy];
    }

    verifyMemoryManagement();
}

@end
