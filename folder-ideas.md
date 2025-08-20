# Ideas on folders:

## Core

A folder MUST track meta-data for it's contents
  - full list of messages
  - flags/tags/whatever
  - implies database.

A folder MUST provide access to messages it contains.
  - might need to request from server (eg IMAP online-only).

A folder MAY store messages locally.
  - offline storage is optional for IMAP folders.
  - virtual folders probably don't store extra copies of emails (check!).
  - IMIncomingServer.jsm has a dummy msgStore (only supportsCompaction).
  - IMIncomingServer does store conversation logs (flat files?)

A folder MAY contain subfolders.

A folder MAY support rename/move
  - news folders can't be renamed

A folder SHOULD be able to rebuild metadata from raw messages?
  - this is currently the case (with caveats).
  - For local folders, database holds only version of metadata?
  - For IMAP, a lot of metadata comes from server? (read, tags...)

Folder naming can be constrained by protocol (and filesystem).

Messages can be moved between folders.

Messages in folders can be deleted
  - Some protocols (eg IMAP) support mark-as-deleted (and an undelete operation)
  - Deletion can mean move-to-trash or actual deletion.

more to come.

## Questions

What is the policy on default folders for various servers?
  - understanding policy is first step to cleaning up the code.
  - eg what conditions cause INBOX to be automagically created?
  - Follow down logic in nsMsgAccount::SetIncomingServer() for various servertypes.

## Ideas

- think of folder as list of messages + metadata.
  Implementations may track servers (IMAP, news, rss, pop), but from outside,
  shouldn't need to care.

- all operations should be async if they need to work with servers. (and
  non-server implementations are just quicker, but still have same APIs).

- virtual folders should be own class rather than a flag on other classes?

- message database is currently per-folder. Should be per-server, at least,
  maybe even global. There are Bug to track this (TODO)
  rationale: avoid storing multiple copies of the same message
  Q: where does the actual message reside on filesystem?
  (note: There are already some hacks for sharing emails over multiple gmail
  folders!)

- Why do we need all the per-protocol folder types?
  Can we just have a core folder class which implements all the required features?
  (with maybe a separate class for virtual folders).
  What would the folder-protocol interface need to look like?

-  Same goes for database types: nsMailDatabase, nsNewsDatabase, nsImapMailDatabase etc

- Non-local folders shouldn't have msgStore set (eg Virtual folders, online-only IMAP, etc). (from Bug 1533624).


## Simultaneous copy operations

[source](https://bugzilla.mozilla.org/show_bug.cgi?id=1980509#c3)

To be fair, it's probably Okay-ish to use nsIMsgFolder.copyMessages().
It's the core thing for copying messages into the folder from some other folder, and it's a pretty solid interface and should be well defined (overlooking awfulness of taking an nsIMsgWindow, and the innappropriateness of taking nsIMsgCopyServiceListener as the listener! :-).

nsIMsgCopyService really just adds a copy queue on top of that and tries to civilize things.
But that's only needed because the folder copyMessage() implementations are all a bit shonky.
There's no fundamental reason why a folder could not have simultaneous copies to it all happening at once. If the folder really does have some core serial property to it (eg writing to an mbox), then it should be able to hold up multiple copies and serialize them, the callers being none the wiser. We've got async support (via the listener) so we should be taking advantage of that.
(Just a thought for when we start thinking about refactoring the folder/protocol stuff, post-ews)

