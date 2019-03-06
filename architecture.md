# Folders

TODO: more details here!

TODO: discuss folder lookup service and folder creation
`comm/mailnews/base/src/folderLookupService.js`

Notes:
- Virtual folders are just normal folders with the `Virtual` flag set.

The folder type is determined by the incoming server type.
ie nsImapIncomingServer servers always create nsImapMailFolder folders.

### folder creation

incomingserver knows how to create it's own root folder.

nsIMsgFolder defines:

createSubfolder
- for gui code to use
- takes a window as param and may be async

`addSubfolder` - adds a child folder
- implemented by nsMsgDBFolder
- nsImapMailFolder overrides with own implementation (used
  only for virtual folders)
- returns `NS_MSG_FOLDER_EXISTS` if child already exists
- fiddles the child name for Inbox, unsent, draft, trash etc etc


Virtual folders are created by:
nsMsgAccountManager::LoadVirtualFolders()
which loads `virtualFolders.dat` (by default. it's user-configurable)

## nsIMsgFolder

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

implementations (via nsMsgDBFolder):
- nsImapMailFolder
- nsMsgLocalMailFolder
- nsMsgNewsFolder
- JaBaseCppMsgFolder

## nsMsgDBFolder

`comm/mailnews/base/util/nsMsgDBFolder.h`

inherits from:
- nsRDFResource
- nsSupportsWeakReference
- nsIMsgFolder
- nsIDBChangeListener
- nsIUrlListener
- nsIJunkMailClassificationListener
- nsIMsgTraitClassificationListener

base nsIMsgFolder implementation for folders that use an nsIMsgDatabase.

Not sure there are any nsIMsgFolder implementations which _don't_ use a
nsIMsgDatabase...

msgStore attribute is implmented to just pass through the nsIMsgPluggableStore
of the server.

nsMsgDBFolder defines the location for the summary (.msf) file.
see GetSummaryFile()

Defines a virtual function, `CreateChildFromURI()` which is implemented
by derived classes to create the right kind of new folder object.


## nsImapMailFolder

`comm/mailnews/imap/src/nsImapMailFolder.h`

inherits:
- nsMsgDBFolder
- nsIMsgImapMailFolder
- nsIImapMailFolderSink
- nsIImapMessageSink
- nsICopyMessageListener
- nsIMsgFilterHitNotify

TODO: more details!

There can be a .msf file, even without a folder directory.
The folder is created on-demand, when a message is completely
downloaded from the server and stored locally.
The .msf file alone is enough to display the list of messages in the gui.

## nsIMsgLocalMailFolder

`comm/mailnews/local/public/nsIMsgLocalMailFolder.idl`

assorted local-folder stuff... default flags for subfolders, helpers for
creating local folders and wrangling messages...?

## nsMsgLocalMailFolder

`comm/mailnews/local/src/nsLocalMailFolder.h`

inherits from nsMsgDBFolder, nsIMsgLocalMailFolder, nsICopyMessageListener

used for both local folders and pop3?
(also used as offline store for Imap folders???)


## nsIMsgNewsFolder

`comm/mailnews/news/public/nsIMsgNewsFolder.idl`

## nsMsgNewsFolder

`comm/mailnews/news/src/nsNewsFolder.h`

Inherits from nsMsgDBFolder, nsIMsgNewsFolder




# Message Databases

## nsIMsgDatabase

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
## nsMsgDatabase

`comm/mailnews/db/msgdb/public/nsMsgDatabase.h`

Only concrete implementation of `nsIMsgDatabase`?


## nsIMsgDBService

A service to open mail databases and manipulate listeners automatically.


## nsIMsgDBHdr

Common headers exposed as attributes (`messageId`, `subject` etc...)

Can store general properties (indexed by string)

## nsMsgHdr

Only concrete implementation of nsIMsgDBHdr?

Knows about the `nsMsgDatabase`, and which row it occupies.

## nsIMsgIncomingServer

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

Q: do all folders have a nsIMsgIncomingServer? Even local folders?


# Pluggable Mail Stores

## nsIMsgPluggableStore

`comm/mailnews/base/public/nsIMsgPluggableStore.idl`

background notes:

    https://wiki.mozilla.org/Thunderbird:Pluggable_Mail_Stores

DeleteFolder: just deletes the actual file/folders. Not concerned with .msf files.

current implementations are:

- nsMsgBrkMBoxStore
- nsMsgMaildirStore

## nsMsgBrkMBoxStore

`comm/mailnews/local/src/nsMsgBrkMBoxStore.h`

Implements mbox storage.

inherits: nsMsgLocalStoreUtils, nsIMsgPluggableStore

## nsMsgMaildirStore

`comm/mailnews/local/src/nsMsgMaildirStore.h`

Implements maildir storage.

inherits: nsMsgLocalStoreUtils, nsIMsgPluggableStore


# IMAP

## nsIMsgIncomingServer

`comm/mailnews/base/public/nsIMsgIncomingServer.idl`

```
/*
 * Interface for incoming mail/news host
 * this is the base interface for all mail server types (imap, pop, nntp, etc)
 * often you will want to add extra interfaces that give you server-specific
 * attributes and methods.
 */
```

nsIMsgIncomingServer has methods/attributes for things like:

- prettyname
- hostname/port/password
- the nsIMsgPluggableStore to use
- biff details
- serverURI (uri for root mail folder)
- root folder
- filters
- offline support level
- assorted prefs and settings

TODO: do local (non-pop3) folders have an incomingserver?

"Deferred" accounts refer to accounts which share a global inbox,
rather than having their own local folders.
See: 
    http://kb.mozillazine.org/Thunderbird_:_FAQs_:_Global_Inbox

uri schemes:
- "none"
- "pop3"
- "imap"
- "rss"
- "movemail" (behind #ifdef switch)
- "nntp"

## nsMsgIncomingServer

Base class for common functions. Not for standalone use.

Inherits:
- nsIMsgIncomingServer
- nsSupportsWeakReference
- nsIObserver

inherited by:
- nsMailboxServer
- nsNntpIncomingServer
- nsImapIncomingServer
- JaBaseCppIncomingServer

## nsImapIncomingServer

Inherits:
- nsMsgIncomingServer
- nsIImapIncomingServer
- nsIImapServerSink
- nsISubscribableServer
- nsIUrlListener

uri scheme: "imap"

Its `CreateRootFolder()` creates `nsImapMailFolder` type

## nsMailboxServer

Dummy no-nothing server for local folders?

Inherits:
- nsMsgIncomingServer

Inherited by:
- nsPop3IncomingServer


implements only 3 functions:
- `GetLocalStoreType()` - always `mailbox`
- `GetDatabaseType()` - always `mailbox`
- `CreateRootFolder()` - creates `nsMsgLocalMailFolder` type


## nsPop3IncomingServer

Inherits:
- nsMailboxServer
- nsIPop3IncomingServer
- nsILocalMailIncomingServer

uri scheme: "pop3"

Doesn't implement it's own `CreateRootFolder()`, just uses
`nsMailboxServer::CreateRootFolder()` which creates
`nsLocalMailFolder`.

## nsNntpIncomingServer 

Its `CreateRootFolder()` creates `nsMsgNewsFolder` type

# account manager

##  nsMsgAccountManager

`comm/mailnews/base/src/nsMsgAccountManager.h`

inherits:
- nsIMsgAccountManager
- nsIObserver
- nsSupportsWeakReference
- nsIUrlListener
- nsIFolderListener



