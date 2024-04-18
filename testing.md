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


Each test file (`test_blahblahblah.js`) is run individually, sandwiched
between the head and tail js files.
The head/tail files will be run for every test file.

So, for example, every test file sees it's own unique profile directory
for `do_get_profile()`.

If a test is still running after 5 minutes, it will timeout (and fail).

# mochitest

eg:

    $ ./mach mochitest --headless --log-mach - --log-mach-level debug comm/mail/test/browser/composition/browser_addressWidgets.js

`--log-mach` to get human-readable output.

# gtests (C++ unit tests)

    $ ./mach gtest "Strings.*"

