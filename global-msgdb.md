# notes on experimental global msgdb C++/sqlite


## Current situation

Each folder has it's own mork database.
Mork doesn't impose a set schema - more like a key-value store.
Makes it tricky to figure out exactly what's in there.
Different systems and protocols add their own ad-hoc fields.

nsIMsgDatabase
- represents DB for a single folder
- contains messages, folder info, some misc other stuff
- there are multiple concrete classes for various protocols.
- DB can have listeners which are notified when messages change.

nsIMsgDBHdr
- concrete class is nsMsgDBHdr
- represents a single message
- nsMsgDBHdr is a lot thinner than I realised. It's really just a live
  connection to a db.
- usually linked to message in DB, but can be non-attached (eg when building
  up new messages).
- nsMsgDBHdr caches a few fields (flags, references, date etc).
- nsMsgDatabase caches nsMsgDBHdrs
- messages can (usually) only be in a single folder.
- changing nsIMsgDBHdr directly doesn't trigger nsIMsgDatabase listener notifications (TODO: Confirm this!)

nsMsgKey (aka `uint32_t`)
- `nsIMsgDBHdr.messageKey`
- 32 bit identifier
- unique within folder
- IMAP: the message key is set to the UID of the message.
- IMAP: when UIDVALIDITY changes, the DB is blown away and resynced.

gmail hack
- specific to gmail IMAP
- allow messages to appear in more than one folder
- uses X-GM-MSGID.
- It's a bit icky.

threading representation
- nsIMsgThread et al
- a bit cumbersome and complicated
- Threads are _within_ folder. No cross-folder threading.

### Problems with current system

- per-folder database makes it an arse to have a conversation view which
  spans multiple folders (eg likely that some replys might be in your
  "Sent" folder).
- The Add-on which did conversation views used the gloda search mechanism
  hack up cross-folder conversations. Slow, complicated.
- the gmail multi-folder hack is icky.
- Nobody understands Mork.
- loads of voodoo code where folder database handles are nulled to avoid
  filehandle exhaustion. Unecessary, and means that folder
  code has to deal with missing database. Overcomplicated and bonkers.
- commit model is iffy. All code just assumes it can magically change
  message fields at will, and there are commits peppered around the place.

## The C++/Sqlite plan

- use a single sqlite database for all folders
- use global 64bit nsMsgKey, not per-folder
- allow messages to be in more than one folder
- can now do whole-database queries. Not restricted to within folder.
- threading representation can now go across folders.
- keep existing interfaces (nsIMsgDatabase, nsIMsgDBHdr nsIMsgThread) as much
  as possible to keep existing code working. At least initially.
- can't do much about iffy commit model yet - just apply all changes
  immediately as per mork. But eventually it'd be nice (and faster and more
  error-tolerant) to bound message operations in some sort of transaction.

GlobalDB
- Underlying class to manage single global DB. Not (yet) exposed to JS.
- Just add methods ad-hoc for now to support nsIMsgDatabase/nsIMsgHeader etc

nsIMsgDBHdr
- now represents a view of a message in a specific folder.
- can have multiple nsIMsgDBHdrs which represent the same message, but in different folders
- changes made in one hdr should be reflected in others (eg clearing the "UnRead" flag).

nsIMsgDatabase
- now represents just the messages in a single folder. A subset of full global DB.


## Misc Thoughts

### Message copying/moving

I had originally thought that this would allow us to do trivial message
copies - just create a new entry for same message, but in the destination
folder. If we've got a full local copy of a message, then leave it where it is and
let both entries use that same data.

However, there are a bunch of reasons I don't think this flies:
- even with local folders and mbox files, you'd expect the mbox file to exactly
  match the messages listed in your folder.
- email messages don't have a proper unique ID (Message-ID can't be relied on)
- X-GM-MSGID IMAP extension or equivalent does provide a proper unique ID.

So I think by default we should do dumb full copies as we currently do.
But for messages that _do_ have a proper unique ID, we should allow them to be
appear in multiple folders.
For local messages, this means adding a new DB entry to show the same message
in multiple folders.
For IMAP, this would mean extending X-GM-MSGID support to tell the server
we're just assigning the existing message to another mailbox, not creating a new message.

### Message Threading/conversation view

Conversation view becomes easy if DB provides proper threading info.

How do we deal with showing threads in folders which only have _some_ of the messages?
eg Copy a few messages in a large thread from one folder to another. How should those messages be threaded in the second folder?
UI clues? Show "other-folder" messages as ghosted?
Treat them as a separate mini thread?

How does gmail web interface handle this?


### Message storage

If the same message can appear in multiple folders, need to track where local message is stored (ie only want one copy).
storeToken needs to be associated with a folder.
Maybe should separate out local storage as a concept (and table to link them).


### IMAP

IMAP uses UID as message key. This is pain.
We want to let the GlobalDB assign it's own global message keys.

Plan is to change IMAP code to store UID separately.

So need to audit all uses of messageKey in the IMAP code, and figure out which
ones need to use the separate UID instead.
This is a big job.

Bottom line: DB should be the only thing setting message keys.
This work _could_ be done pre-GlobalDB, on the existing mork msgDB, but
migration is an issue, and probably not worth it. So probably best to do it
along with the global msgDB work.

### Commit model


Currently msgDB has pretty ad-hoc commit model.
And error handling sucks (waaaaay to easy for partial modifications to
get into db).

For now, just run without transations or use the existing commit hints.
But longer-term, the DB should have a better-defined transaction model,
to improve error handling. 

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


