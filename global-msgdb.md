# notes on experimental global msgdb C++/sqlite

nsMsgDBHdr is a lot thinner than I realised. It's really just a live
connection to a db.

caching:
- nsMsgDBHdr caches a few fields (flags, references, date etc).
- nsMsgDatabase caches nsMsgDBHdrs
- try ditching them all and just relying on sqlite caching
- failing that, try caching individual fields inside GlobalDB (rather than in
  nsMsgHdr).


## Issues

### nsIMsgDBHdr

Should header represent a single message (which could be in multiple folders),
or should it be a message+folder combo?
(so the same message could have multiple msgHdrs, one per folder).

Current model leans toward a msgHdr being a view of a message in a specific folder.
So the same message in a different folder would have a different msgHdr.

Issues with DB caching: some fields are per-message (eg flags), others are
per-message-per-folder (eg IMAP UID).

### Threading

How do we deal with showing threads in folders which only have _some_ of the messages?
Copy a few messages in a large thread from one folder to another. How should those messages be threaded in the second folder?
UI clues? Show "other-folder" messages as ghosted?
Treat them as a separate mini thread?

How does gmail handle this?

### Message storage

If the same message can appear in multiple folders, need to track where local message is stored (ie only want one copy).
storeToken needs to be associated with a folder.
Maybe should separate out local storage as a concept (and table to link them).


### IMAP

Looks like IMAP uses message key to store UID.
So need to have a dedicated IMAP UID field instead.
Same probably goes for NNTP.
Likely to be some odd assumptions in IMAP folder code regarding this which
will need to be fixed up...

Tuple (Mailbox + UIDVALIDITY + UID) gives individual IMAP message.
We can represent it as folder+UID in the db maybe (Mailbox + UIDVALIDITY is implied by folder).

Bottom line: DB should be the only thing setting message keys.
Could do the work to store explicit UID in existing msgDB, but migration is an issue.

Need to audit all uses of SetMessageKey and GetMessageKey in imap code.

### Commit model

Currently msgDB had pretty ad-hoc commit model.
And error handling sucks (waaaaay to easy for partial modifications to
get into db).

For now, just run without transations or use the existing commit hints.
But longer-term, the DB should have a better-defined transaction model,
to improve error handling. 


## Future

### Unify database views?

We've currently got per-folder nsMsgDatabase objects, and DB views.
Seems like this could all be unified, including fulltext indexing (gloda)
and virtual folders.

We could just have a single view, which takes a filter to match messages of a certain criteria.
GUI shouldn't have to care how the message list in the view is calculate. It should just be able to say things like:
 - Give me a list of all messages with "grapefruit" in the subject or body text, which are in the "INBOX" folder, sorted by ascending date.

Existing nsMsgDatabase classes become views which return all the messages in a certain folder.


TODO: survey existing message db view classes (in C++ and JS).


## Misc

### Use JMAP for data modelling inspiration

https://jmap.io/spec-mail.html
rationale: they've spent a lot more time thinking about it than we have!
It also takes into account real-world implementations, such as gmail.


### IMAP should improve support for (some) gmail extensions

https://developers.google.com/gmail/imap/imap-extensions

In particular, X-GM-MSGID seems to be the only sensible solution currently
out there for identifying the same message appearing under multiple folders.
We already do this to a degree, but it's a little hacky.

Discussion [here](https://bugzilla.mozilla.org/show_bug.cgi?id=721316).

TODO: survey what we currently support and see what should happen next.


