# Notes on Compact/Expunge

- Compact mostly refers to removing deleted messages from the mailstore.
  - only really required to compress gaps on mbox
  - on maildir deletes actually delete the message? (check this!)

When user sets off a compact operation:

- local folders: just compacts the store.
- IMAP:
  1) Apply retention settings
  2) Compact store
  3) send an Expunge
- news?
- feeds?

Compact functions take an optional nsIUrlListener.
- nsIUrl listener seems to be used as a general callback. No url is involved.
- OnStartRunningUrl() will not be called.
- OnStopRunningUrl() will be called (with a null uri) when compact completes.
- Folder notifications will also happen:
  - via mailsession:
    - nsIFolderListener.OnItemEvent(kCompactCompleted) - local folders only!
  - via folder notification service:
    - nsIMsgFolderListener.folderCompactStart()
    - nsIMsgFolderListener.folderCompactFinish()

# nsIMsgFolderCompactor

- Implemented by nsFolderCompactState.
- Works by copying all messages using mailboxservice.
- If a window is given, it'll update the status message.
- uses the nsIMsgFolderNotificationService to notify start/end of folder compaction



