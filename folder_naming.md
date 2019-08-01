# Folder Naming

Currently there are a bunch of bugs related to folder naming.
I think a lot comes down to the ad-hoc nature of naming, so this is
an attempt to try and nail things down a little.

## User-facing names

- As displayed in the folder tree UI panel.
- Should be able to contain any printable characters: non-latin, '/','\' etc.
- TODO: which `nsMsgFolder` attr is used?

## nsMsgFolder name attr

- Internal name
- Used to derive URI? (TODO: confirm)

## MailStore (ie mbox/maildir on filesystem)

- Allowed characters depends on OS (ie no backslashes etc)
- Case-sensitivity depends on OS
- Some names have special significance? "INBOX", "Trash" etc. Sets flags on the folder.
- Folder discovery iterates over filesystem names, and uses those names for the UI
  => some names are tweaked/localised when mapped to UI, eg "INBOX" -> "Inbox"
  => TODO: where is this mapping performed?
- should be able to copy folders across OSes? (ie should enforce a common
  subset of naming rules?)
- TODO: link to unix, windows filesystem naming rules
- Numeric suffix added to deduplicate... eg "INBOX-1" (TODO: why is this needed? How does it work with folder discovery?)

## IMAP folders

- TB queries IMAP server to find remote folders.
- Base IMAP has ascii names, but extensions handle full unicode (TODO: confirm)
- Takes time to ask server. Usually, if there's a mailstore (filesystem) folder that will be picked up first.
- Missing mailstore folders are created as needed (TODO: identify code that does this). Eg, for a new TB install.

## Folder URIs

- Full identity of a folder within TB
- stored in VirtualFolders.dat, and elsewhere
- what are the current encoding rules? What _should_ they be?

## VirtualFolders.dat

- Contains URI of virtual folder
- Creates a nsMsgFolder with names based upon URI
- TODO: which class holds `LoadVirtualFolders()`/`SaveVirtualFolders()`?


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

