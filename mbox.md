# Thunderbird mbox format


Thunderbox mbox seems to have a few quirks, compared to the mbox standards (such as they are):

- no blank lines between messages
- older versions of Thunderbird placed used lines with "From " and nothing else as separation markers.
- newer versions use markers like: "From - Sat Apr 19 19:23:12 2014"
(note hyphen in place of email address)
- older Thunderbird does not escape lines in message content beginning with "From ".
- newer Thunderbird prefixes a space to such lines


## mbox <-> maildir conversion

The converter script that handlers conversions performs it's own mbox parsing, which
may have extra quirks that need to be dealt with...

    mailnews/base/util/mailstoreConverter.jsm
    mailnews/base/util/converterWorker.js

see:
    https://bugzilla.mozilla.org/show_bug.cgi?id=1491228


## Other mbox documentation

    https://tools.ietf.org/html/rfc4155
    http://kb.mozillazine.org/Importing_and_exporting_your_mail#Mbox_files
    http://www.qmail.org/man/man5/mbox.html
    https://en.wikipedia.org/wiki/Mbox

