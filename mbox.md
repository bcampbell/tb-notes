# Thunderbird mbox format

## Current mbox usage in TB

- no blank lines between messages
- older versions of Thunderbird placed used lines with "From " and nothing else as separation markers.
- newer versions use markers like: "From - Sat Apr 19 19:23:12 2014"
(note hyphen in place of email address)
- older Thunderbird does not escape lines in message content beginning with "From ".
- newer Thunderbird prefixes a space to such lines

## Goals

Want to be leinent on what we'll read, and ultra-strict on what we write.

TODO: define and document exact output format.

MUST be able to read all previous forms of mbox written by TB. This means:
- accept unescaped "From " lines in body (check if following lines are headers).

Would like to read as many mbox variants as we can.

## Questions

Doesn't look like there's anything that says RFC2822 message bodies need to end with a end-of-line.
But we need an end-of-line before our "From " lines.
Should we just add an end-of-line to every message when writing, and strip it when reading?

The "default" mbox format at https://datatracker.ietf.org/doc/html/rfc4155#appendix-A says that LF should be used for end-of-line, not CRLF.
Even in the RFC2822 message (which would usually be CRLF).
Should we do CRLF <--> LF conversions when reading/writing messages to mbox?
(gut feeling: no - it's an irreversible transformation, and it seems like we should be able to retreive messages _exactly_ byte-for-byte as we write them in).

https://www.loc.gov/preservation/digital/formats/fdd/fdd000383.shtml states that mbox always has a blank line after the RFC2822 message, and before the "From " separator line (except for the first message).
The example mbox on https://en.wikipedia.org/wiki/Mbox seems to back this up.


## Other mbox documentation

    https://tools.ietf.org/html/rfc4155
    http://kb.mozillazine.org/Importing_and_exporting_your_mail#Mbox_files
    http://www.qmail.org/man/man5/mbox.html
    https://en.wikipedia.org/wiki/Mbox
    https://www.loc.gov/preservation/digital/formats/fdd/fdd000383.shtml

