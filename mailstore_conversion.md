# Notes on MailStore conversion

When the user switches from mbox to maildir or vice versa, the
conversion is handled by:

    mailnews/base/util/mailstoreConverter.jsm
    mailnews/base/util/converterWorker.js

The conversion is very dependent on the type of the stores
and the type of folders - there are lots of checks and special
cases.

The converter iterates through the filesystem directly to
discover the messages.

Once the folders have been converted, Thunderbird is restarted
to pick up the new ones.

## Use xpcom nsIMsgPlugableMailstore to read & write messages

This would avoid having duplicated maildir/mbox parsing code.

The issue is that you can't call xpcom from worker threads,
and a long-running operation like this needs GUI progress
feedback. So this might not be possible.

Ideas to get around this:

- could the C++ side accept a listener which informs the GUI?
- could the C++ side be made fast enough that it's not even an
  issue? After all, it's just file copying so we should be able
  to shift vast amounts of data very quickly.

## clean up mailstoreConverter.jsm-worker interface

Currently the main thread just passes an array to the worker,
and the worker does some voodoo to work out what it should do.

Worker should just be told:
"convert this maildir dir to this mbox file" or
"split this mbox file into this maildir"

Main thread should handle all the directory hierarchy gubbins.

Could (should) even have separate workers for each direction.

## better progress feedback from worker

Currently, assumes that file counts stay in sync. Should
define better protocol for sending progress, completion and
errors back to main thread.

## use OS.File APIs instead of nsIFile

Seems like that's the way the codebase is going?
Also, can use from worker thread.


