# static analysis

Integrated into clang (some custom modules, some off-the-shelf).
Check for common C++ errors, or stuff against policy.

    $ ./mach static-analysis check
or
    $ ./mach static-analysis check path/to/file.cpp


# xpcshell unit tests:

    $ ./mach xpcshell-test

single file eg:

    $ ./mach xpcshell-test comm/mailnews/imap/test/unit/test_converterImap.js

# mozmill tests

Whole-app tests run by driving the compiled app remotely.

To run a single test:

    $ cd obj-x86_64-pc-linux-gnu/
    $ make SOLO_TEST=attachment/test-attachment-multiple.js mozmill-one

run a whole directory of tests:
    $ make SOLO_TEST=attachment mozmill-one

