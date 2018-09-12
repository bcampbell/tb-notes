








# nsIMsgFolder

`comm/mailnews/base/public/nsIMsgFolder.idl`

Abstract interface for a folder, which might be a newsgroup, imap folder etc

message access/iteration/manipulation
name and id
parent/children
server
filter list
filePath
Properties
offline storage (optional)
nsIFolderListener registration
Property-change notification handlers
pluggable store (msgStore)  - maildir or mbox
summaryFile (the .msf file)
`nsIMsgDatabase` (`msgDatabase` attribute, rw)

TODO: how do summaryFile and msgDatabase interact?

# nsMsgDBFolder

inherits from:
- nsRDFResource
- nsSupportsWeakReference
- nsIMsgFolder
- nsIDBChangeListener
- nsIUrlListener
- nsIJunkMailClassificationListener
- nsIMsgTraitClassificationListener

nsIMsgFolder implementation for folders that use an nsIMsgDatabase.

Not sure there are any nsIMsgFolder implementations which _don't_ use a
nsIMsgDatabase...

msgStore attribute is implmented to just pass through the nsIMsgPluggableStore
of the server.


# nsImapMailFolder

`comm/mailnews/imap/src/nsImapMailFolder.h`

inherits:
- nsMsgDBFolder
- nsIMsgImapMailFolder
- nsIImapMailFolderSink
- nsIImapMessageSink
- nsICopyMessageListener
- nsIMsgFilterHitNotify

TODO: more details!



# nsIMsgDatabase

inherits from: nsIDBChangeAnnouncer

opened on a specific, single `nsIMsgFolder` (in readonly `folder` attribute)

opened/created solely via nsIMsgDBService?

stores nsIMsgDBHdr objects, accessed by `nsMsgKey` (a `uint32_t`).

has methods for adding, removing, iterating and searching nsIMsgDBHdrs.

```
* This module is the access point to locally-stored databases.
 *
 * These databases are stored in .msf files. Each file contains useful cached
 * information, like the message id or references, as well as the cc header or
 * tag information. This cached information is encapsulated in nsIMsgDBHdr.
 *
 * Also included is threading information, mostly encapsulated in nsIMsgThread.
 * The final component is the database folder info, which contains information
 * on the view and basic information also stored in the folder cache such as the
 * name or most recent update.
 *
 * What this module does not do is access individual messages. Access is
 * strictly controlled by the nsIMsgFolder objects and their backends.
```
# nsMsgDatabase

comm/mailnews/db/msgdb/public/nsMsgDatabase.h

Only concrete implementation of `nsIMsgDatabase`?


# nsIMsgDBService

A service to open mail databases and manipulate listeners automatically.


# nsIMsgDBHdr

Common headers exposed as attributes (`messageId`, `subject` etc...)

Can store general properties (indexed by string)

# nsMsgHdr

Only concrete implementation of nsIMsgDBHdr?

Knows about the `nsMsgDatabase`, and which row it occupies.

# nsIMsgLocalMailFolder

assorted local-folder stuff... default flags for subfolders, helpers for
creating local folders and wrangling messages...?

# nsMsgLocalMailFolder

inherits from nsMsgDBFolder, nsIMsgLocalMailFolder, nsICopyMessageListener

some helpers for pop3 download/storage?

# nsIMsgIncomingServer

```
/*
 * Interface for incoming mail/news host
 * this is the base interface for all mail server types (imap, pop, nntp, etc)
 * often you will want to add extra interfaces that give you server-specific
 * attributes and methods.
 */
```
base interface for:
- nsMsgIncomingServer
- nsImapIncomingServer
- nsPop3IncomingServer
- nsNntpIncomingServer



# nsIMsgPluggableStore

    https://wiki.mozilla.org/Thunderbird:Pluggable_Mail_Stores

