# Set debug build

add this line to `mozconfig`:

    ac_add_options --enable-debug


# GDB

[See also](https://developer.mozilla.org/en-US/docs/Mozilla/Debugging/Debugging_Mozilla_with_gdb)

## setup

add to ~/.gdbinit (or create if not already present):

    add-auto-load-safe-path /home/ben/src/source/.gdbinit

(actually, /home/ben/src/ is probably enough)

## run a build under gdb

    $ ./mach run --debug

## run a test under gdb (eg)

    $ ./mach xpcshell-test --debugger gdb --debugger-interactive comm/mailnews/extensions/bayesian-spam-filter/test/unit/test_customTokenization.js

## Dump out JS call stack:

    (gdb) call DumpJSStack()


# Logging

see https://wiki.mozilla.org/MailNews:Logging for details.

To turn on logging:

    $ export MOZ_LOG="BayesianFilter:5"
eg
    $ export MOZ_LOG="timestamp,IMAP:5,POP3:5,NNTP:5,SMTP:5,sync"

Use `MOZ_LOG_FILE` to log to file instead of stderr, eg:

    $ export MOZ_LOG_FILE="/tmp/tb_log.txt"

Log levels:

0: disabled, 1: Error, 2: Warning, 3: Info, 4: Debug, 5: Verbose

## Log4Moz stuff

A bunch of javascript modules have logging via Log4Moz (see comm/mailnews/db/gloda/modules/Log4Moz.jsm).

These can log to the javascript console and/or stdout.
This is controlled by prefs.

E.g., if the loggername is foo, then look for prefs
   *   foo.logging.console
   *   foo.logging.dump

Values are: 'Fatal', 'Error', 'Warn', 'Info', 'Config', 'Debug', 'Trace', 'All'.

E.g. to dump all account creation logging (logger: "mail.wizard") to stdout:
```
user_pref("mail.wizard.logging.dump", 'All');
```

## logging NSPR stuff

eg:

    $ export NSPR_LOG_MODULES="pipnss:5"

# Assertions

By default, `NS_ASSERTION` just prints out a warning message and continues.

Use XPCOM_DEBUG_BREAK to change this, eg:
```
$ export XPCOM_DEBUG_BREAK=suspend
```
other values: break, stack


# Force debug break in code:

For intel 32/64 bit:

      __asm__("int $3");

# run dummy smtp server

    $ python -m smtpd -n -c DebuggingServer localhost:6502

