# Demboxification

## The issue

Historically, mbox was the only local storage format that was supported by Thunderbird, and so mbox-specific assumptions are all over the codebase.
This overcomplicates a lot of code and makes it much harder to seamlessly integrate other backends (such as maildir).

## Goal

All mbox-specific functionality should be contained by nsMsgBrkMBoxStore:

- dealing with "From " separator lines between messages
- quoting/unquoting lines in message bodies which begin with "From ".
- mbox compaction
- mbox reparsing (local folder repair)

## Steps

- nsIMsgPluggableStore.getMsgInputStream() should serve a single message followed by an EOFs.
- Streams supplied by nsMsgBrkMBoxStore handle "From " separators and "From "-escaping internally. Both for reading and writing.
- Folder compaction should be moved behind nsMsgBrkMBoxStore (compaction is mbox-only).
- nsMsgBrkMBoxStore to provide support for localfolder "repair folder", by providing an iteration mechanism.
- Remove "From " handling from everywhere else in the code.
- Fix tests and testdata which expect/contain mbox "From " lines.
- Add unit tests to ensure no leakage of "From " lines outside mbox msgStore.

## Implementation notes

"From "-escaping is only performed upon the body of a message and not the header.
This means that reading and writing messages cannot be a dumb operation - the
message must be parsed, at least as much as knowing where the header block ends.

We should be strict when we write to mbox files: there should be no way to write an ambiguously-quoted message into an mbox.

We should be tolerant about how we read mbox files:
- mbox files in the wild may have missing or incorrect "From " quoting.
- Incoming messages may have leading "From " lines 
- Exported messages and test data may have leading "From " lines

TODO: can we repair bad messages? Will that screw anything up?

## Relevant bugs

Bug 1719121 - Confine "From " line handling to mbox-specific code
(+ lots of dependent bugs)

Bug 1733849 - nsIMsgPluggableStore.getMsgInputStream() should return a stream for a single message, not entire mbox


