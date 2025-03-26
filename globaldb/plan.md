# GlobalDB - The Plan

## Overall goals

- Replace the existing per-folder legacy mork database system with a global database.
- Implement legacy interfaces on top of new global DB so app continues to work.
- Implement better, simpler APIs (LiveView etc) on top of the globalDB and transition over.
- Remove all the legacy DB code and interfaces.

## Steps

1. Implement the global database (at least enough of it)
2. Implement the legacy interfaces to run against Panorama rather than mork.
  This boils down to implementing Panorama-aware versions of:
    - `nsIMsgDatabase` (there are some derived classes for various protocols, but really easiest to think of them all as one).
    - `nsIMsgDBHdr` - represents a single message, in a single folder.
    - `nsIMsgThread` - The model for threaded conversations, within a folder.
    - `nsIMsgDBService` - responsible for opening and caching databases.
    - `nsIFolderInfo` - persists assorted folder settings in the database.
3. Fix whatever needs fixing to get the existing stuff up and running against Panorama.
   (see below)
4. Solid data migration path from old system (import data from mork to panorama)
5. Use fancy new Panorama features and phase out the legacy interfaces
    - LiveViews etc.
    - Replace gloda by integrating full-text searching into Panorama.
6. Remove the legacy database code and interfaces completely.

## Milestones

1. Get globalDB working on top of old interfaces enough to get POP3 working.
2. Support EWS.
3. Support NTTP (good practice for IMAP).
4. Support IMAP.
5. Get message filtering working.
2. Implement a solid data migration path from mork to globalDB.
6. Implement alternate GUI (on top of LiveView et al).
7. Remove legacy interfaces and code.


## Known issues

### nsMsgKeys are only 32bit

32 bits probably isn't enough for a global database, especially if there's a lot of turnover.
There could be some clever ID reclamation system, but really we should just bite the bullet and go to 64 bits.
Simply switching to a 64bit `nsMsgKey` is fine for the new code, but could cause a lot of issues in old code.

For now we'll probably leave the nsMsgKey at 32bits while Panorama is in its development phase.


### Definition of `nsMsgKey_None` as 0xFFFFFFFF.

`nsMsgKey_None` is currently defined as `0xFFFFFFFF` (AKA `uint32_t` -1).

A value of `0` is probably better for Panorama (SQL databases tend not to use `0` for auto-assigned primary keys).

In any case, a special value of `0xFFFFFFFF` is no good for a 64bit nsMsgKey.

The C++ side is probably easy enough to deal with, but there are a lot of `0xFFFFFFFF`s out there in javascript, and likely a bunch of `-1`s to pick through too.

For now, Panorama can probably fudge things by massaging any potentially-None nsMsgKeys it returns from it's API, but at some point we'll need to deal with it.

### IMAP/News won't work.

Currently IMAP and News use the message UID assigned by the server as the primary database key.
This is no good for a global database as those keys are only unique within a single folder.

The fix is to track server-assigned IDs separately, and let the database assign it's own keys.

[Bug 1806770](https://bugzilla.mozilla.org/show_bug.cgi?id=1806770) - `IMAP shouldn't use UID as message key`.

### Parsing messages and adding to DB relies on detached nsIMsgDBHdr objects

Mork supports editing database rows which are not attached to a table in the DB.
Sqlite does not.

The current code relies heavily upon this fact when adding messages to the database, and often the code that creates the header is a long way away from the place that adds it to the database.

The main approach here is to replace the use of a detached nsIMsgDBHdr with a "here're all the headers, give me the important bits we want to load into the database".

Because the message-adding code is usually so spread out across multiple callbacks, it's not really feasible to implement a separate code path for globaldb using `#ifdef` and prefs.
So we really just need to refactor the legacy code first.
Most of the legacy code (other than filtering - see below) doesn't rely on detached `nsIMsgDBHdr` objects, so it's definitely doable.

[Bug 1952094](https://bugzilla.mozilla.org/show_bug.cgi?id=1952094) - `Stop using detached nsIMsgDBHdr objects`

[Bug 1876407](https://bugzilla.mozilla.org/show_bug.cgi?id=1876407) - `Refactor nsParseMailMessageState et al`

### Message filtering relies on detached nsIMsgHdr objects

The filters operate upon `nsIMsgDBHdr` objects, but often (e.g. POP3 and IMAP incoming messages) these objects are not in the database.
The filter runs, and _then_ the message is added to a database (depending upon which folder it ends up in).
This also causes big complications with local storage - which doesn't have the explicit concept of a detached message.

For the globalDB we can fool the existing filter logic by implementing another `nsIMsgDBHdr` object which just stores fields locally and has no database connection.

But the filter actions (move/copy/delete etc) and local message store _will_ need substantial work.

### Dangling folders

The current code tends to create folders lazily, and there's an assumption that child folders can be created before their parents.

This is silly, and it'd be much much simpler for everyone concerned if folders were created as a part of sensible folder hierarchy from the start.

Ideally, each folder hierarchy would be initially created by the `nsIMsgIncomingServer` object that was responsible for them.

As folders were added and removed (via user operations, or via slower network-based discoveries), child folders should be created by their parent.

TODO: talk about folder URIs here?

[Bug 1679333](https://bugzilla.mozilla.org/show_bug.cgi?id=1679333) - `Remove support for dangling (unparented) folders`


