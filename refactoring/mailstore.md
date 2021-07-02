# nsIMsgPluggableStore refactor notes

## folder paths

Use a string to represent folder paths within store.

Use '/' as separator.

Path components in UTF-8.

Percent-encode each component of path, as per RFC 3986.
https://en.wikipedia.org/wiki/Percent-encoding

/        - root folder
/INBOX   - INBOX


## replace rebuildIndex() with an iterator mechanism

Used _only_ by nsMsgLocalMailFolder::ParseFolder().
comm/mailnews/local/src/nsLocalMailFolder.cpp

move db/folder knowledge out into localmailfolder.

