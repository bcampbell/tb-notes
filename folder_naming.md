# Folder Naming


Bug 1568845
Bug 92165

## Places where folder names are used:

### Folder Name

- The 'canonical'/internal name of the folder.
- in `nsIMsgFolder` name attribute
- Usually the same as the user-facing name (but there _is_ a `prettyName` attr too)
- Used to derive URI in `nsIMsgFolder getURI()` implementations.
- There is some special-case handling for certain folder names - case tweaking, localisation etc. See `nsMsgDBFolder::SetPrettyName()` for an example.
- There is also `abbrieviatedName`, which uses account-specific rules to shorten long names. I think only Newsfolders use it (eg "comp.sys.lang.basic" => "c.s.l.basic").

### User-facing names

- As displayed in the folder tree UI panel.
- Should probably be able to display any printable characters: non-latin chars, '/','\' etc.
- TODO: look in the UI code to see where display name is taken from.

### MailStore (ie mbox/maildir on filesystem)

- The names of files and directories on disk.
- Allowed characters depends on OS
- Case-sensitivity depends on OS
- Some names have special significance? "INBOX", "Trash" etc. Sets flags on the folder.
- Folder discovery iterates over filesystem names, and uses those names for the UI
  => some names are tweaked/localised when mapped to UI, eg "INBOX" -> "Inbox"
  => TODO: where is this mapping performed?
- should be able to copy folders across OSes? (ie should enforce a common
  subset of naming rules? Treat "Stuff" and "stuff" as the same folder on case-sensitive filesystems?)
- TODO: link to unix, windows filesystem naming rules
- Numeric suffix added to deduplicate... eg "INBOX-1" (TODO: why is this needed? How does it work with folder discovery?)

### IMAP folders

- TB queries IMAP server to find remote folders.
- Base IMAP has ascii names, but extensions handle full unicode (TODO: confirm)
- Takes time to ask server. Usually, if there's a mailstore (filesystem) folder that will be picked up first.
- Missing mailstore folders are created as needed (TODO: identify code that does this). Eg, for a new TB install.

### Folder URIs

- Full identity of a folder within TB
- stored in VirtualFolders.dat, and elsewhere
- what are the current encoding rules? What _should_ they be?

=> I think the folder parts of the URI should be UTF-8, then percent-encoded. For example, you should be able to have a folder name in Japanese, say, with a '/' in it eg: "はい/いいえ" ("yes/no").


### VirtualFolders.dat

- Contains URI of virtual folder to create
- Upon loading, creates a `nsDBMsgFolder` with name and parent folder based upon URI
- see `nsMsgAccountManager::LoadVirtualFolders()` and `nsMsgAccountManager::SaveVirtualFolders()`.


## Example Stories

TODO: trace paths of:

1) Create a new local subfolder via UI
2) Create a new IMAP folder
3) Create a virtualfolder (with a tricky character in the name)
4) virtualFolders.dat loaded during startup
5) an `nsIMAPFolder` created by scanning the filesystem, and linked (later!) to one on the IMAP server.
6) other cases?


## Misc notes

- TODO: rename comm/mailnews/news/src/nsNewsFolder.[h|cpp] to nsMsgNewsFolder!

- TODO: survey all the name functions in nsMsgDBFolder
- TODO: note all hard-coded folder names
- sort out/document abbreviatedPrettyName attr. Only used by news folders?


### How folder naming _should_ work (maybe?)

`nsIMsgFolder.name` should be the human readable name, as displayed to the user.
Any valid UTF-8 string.
That's it.

The mapping to the name on the server and/or local filesystem should be defined by the protocol and nsIMsgPluggableStore respectively.

There may be rules to massage/localise names, e.g. IMAP "INBOX" massaged to "Inbox" locally.
That's up to the folder and protocol to sort out when the folder is created.

There also need to be rules to handle the mapping in the other direction.
e.g. if the user creates a folder with the name "I/O stuff", that needs to be mapped to a filesystem-safe name.



`nsIMsgFolder.filePath` should be the _only_ place that exposes the filesystem-safe version of the name.

I think `.name` should be the human readable name, any valid UTF-8 string (e.g. "Inbox", "I/O stuff", "LPT", whatever).

The `.URI` path should consist of URL-escaped `.name` parts.

`.filePath` should be a filesystem-safe path, likely derived from `.name` parts.

Server-side mailbox names (IMAP/EWS/etc) should be dealt with by the folders/protocols - mapped to/from `.name` in some sensible (but protocol-specific way. e.g. for IMAP, the server-side path encoding depends on what separator the server has defined... and that _could_ change between sessions!). In any case, not something to be exposed in the base `nsIMsgFolder` interface.

Not quite sure how `.prettyName` fits in... I'd guess there's some kind of auto localising that happens sometimes... where the "real" name of the folder isn't displayed, but instead a localised version eg `.name`="Trash" but `.prettyName` returns "Garbage" when you switch to American, or "Rubbish" for British (but folder is really called "Trash" all the time).
Maybe?


