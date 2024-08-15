# Notes on nsIMsgCopyService.copyFolder() implementation

- No undo/redo support.
- Synchronous for local folders (probably not for imap?)
- calls OnStartCopy()/OnStopCopy(), at least for local folders.
- invalidates any moved nsIMsgFolder objects (reasonable enough if they're on another incomingserver!).
- nsIMsgCopyService.copyFolder() doesn't detect infinite recursion.


## nsMsgCopyService::CopyFolder():

- creates a new nsCopyRequest
- `copyRequest->Init(nsCopyFoldersType)`
- calls DoCopy()
  - QueueRequest(req)
  - DoNextCopy() if possible
    - type is nsCopyFoldersType
    - call `destFolder->CopyFolder(srcFolder, isMove,window, req->m_listener)`
    - That's it, until folder calls nsIMsgCopyService.notifyCompletion() when done.
      Clean up request, call DoNextCopy().


### nsMsgLocalMailFolder::CopyFolder()

- if folders are on same server, calls CopyFolderLocal(), else calls CopyFolderAcrossServer().

#### nsMsgLocalMailFolder::CopyFolderLocal()

- if destination is a folder under the trash folder:
  - if moving, ask for confirmation (and clear the favourites flag)
  - if a filter destination, ask for confirmation.
- if copying, fail if folder already exists
- if moving and name already exists, create a unique name (with gui confirmation)
- call `msgStore->CopyFolder()` to actually perform the copy.
- done.
NOTE: `nsMsgLocalMailFolder::CopyFolder()` doesn't actually _do_ anything itself!


### nsMsgBrkMBoxStore::CopyFolder() (and maildir equivalent)

- creates a filesystem-safe version of the name
- closes the db of the src folder
- copy mbox file (using the filesystem-safe name)
- copy db file
- call `dstFolder->AddSubFolder()` to create new nsIMsgMailFolder (newFolder).
- open the new db file and set valid
- `newFolder.prettyname = folderName`
- `newFolder.flags = srcFolder.flags`
- update filters and alert the user if any are changed
- copy all child folders (call `folder->CopyFolderLocal()` for each) 
- if isMove and copy succeeded:
  - `localNewFolder->OnCopyCompleted(srcFolder, true)`
  - `destFolder->NotifyFolderAdded(newFolder)`
  - `parent = srcFolder.parent`
  - `srcFolder.parent = null`
  - if parent:
    - `parent->PropagateDelete(srcFolder,false)`
    - delete old mbox file
    - `srcFolder->DeleteStorage()`
    - delete all directories under parent
- if isMove and copy failed:
  - close newFolder db
  - `parent = newFolder.parent`
  - `newFolder.parent = null`
  - if parent:
    - `parent->PropagateDelete(newFolder,false)`
    - `newFolder->DeleteStorage()`
    - delete newFolder mbox file


```
nsMsgDBFolder::CopyFolder()
nsImapMailFolder::CopyFolder()
nsMsgLocalMailFolder::CopyFolder()



```


Local folders

`nsMsgLocalMailFolder::OnCopyCompleted()` invokes `copyService->NotifyCompletion()`
nsIMsgLocalMailFolder.onCopyCompleted is in the IDL.

mbox and maildir also call onCopyCompleted() upon the folder, in their CopyFolder() implementations.



IMAP
OnCopyCompleted() is private
