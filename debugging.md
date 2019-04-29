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

eg
    $ export MOZ_LOG="timestamp,imap:5,pop3:5,nntp:5,smtp:5,sync"


# Assertions


    https://developer.mozilla.org/en-US/docs/Mozilla/Debugging/XPCOM_DEBUG_BREAK

eg:

    $ export XPCOM_DEBUG_BREAK=suspend


# Force debug break in code:

For intel 32/64 bit:

      __asm__("int $3");

# debugging with gdb under mozmill

##attempt 1:

wrap TB bin with a script:

    #!/bin/bash
    here=$( dirname ${BASH_SOURCE[0]} )
    gdb -ex "run" --args $here/thunderbird2 $@

## attempt 2:

hack:
    obj-x86_64-pc-linux-gnu/_tests/mozmill-virtualenv/lib/python2.7/site-packages/mozmill/__init__.py

in MozMill.start(), pass in some `debug_args` when it calls `start()` on the runner, eg:

        self.runner.start(debug_args = ['gdb', '-ex', 'run', '--args'])

Doens't work. Just stalls. Suspect some stdin/out frigging required.

## result:

Just accept defeat and try attaching gdb to the running process instead.

# run dummy smtp server

    $ python -m smtpd -n -c DebuggingServer localhost:6502

