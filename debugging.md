# Set debug build

add this line to `mozconfig`:

    ac_add_options --enable-debug


# GDB

add to ~/.gdbinit (or create if not already present):

    add-auto-load-safe-path /home/ben/src/source/.gdbinit

(actually, /home/ben/src/ is probably enough)

run a build under gdb:

    $ ./mach run --debug

run a test under gdb (eg):

    $ ./mach xpcshell-test --debugger gdb --debugger-interactive comm/mailnews/extensions/bayesian-spam-filter/test/unit/test_customTokenization.js


# Logging

see https://wiki.mozilla.org/MailNews:Logging for details.

To turn on logging:

    $ export MOZ_LOG="BayesianFilter:5"

Also, `MOZ_LOG_FILE` to output to a file.

