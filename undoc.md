


# To Document

## nsIMsgFolder::AddSubfolder()

What happens if folder already exists?
should return `NS_MSG_FOLDER_EXISTS`?

## nsIDBFolderInfo

what is it's intended use? (some notes in nsDBFolderInfo)



## nsIMsgFolder folder deletion functions

  // deletes msf file and calls msgStore to delete storage associated with the folder
  void Delete ();

  // just calls propagateDelete on all given folders (with deleteStorage set)
  void deleteSubFolders(in nsIArray folders, in nsIMsgWindow msgWindow);


  // Deletes a single descendant child folder of this.
  // notifies listeners that the child has been removed
  // (but doesn't tell listeners about any children of that folder that
  // were also zapped)
  void propagateDelete(in nsIMsgFolder folder, in boolean deleteStorage,
                       in nsIMsgWindow msgWindow);

  // recursively deletes this folder and all it's children.
  // If deleteStorage is true, recursively deletes disk storage for this folder
  // and all its subfolders (and NotifyFolderDeleted will be sent to
  // the FolderNotificationService).
  void recursiveDelete(in boolean deleteStorage, in nsIMsgWindow msgWindow);

* nsIMsgImapMailfolder

  // renameLocal renames the msf file and physical files (and folders).
  // should be handled by msgStore?
  renameLocal()


  renameClient()


# TODOs

* unify nsMsgLocalMailFolder::EmptyTrash() and nsImapMailFolder::EmptyTrash()
  Currently nsMsgLocalMailFolder deletes the folder and recreates it.
  nsImapMailFolder deletes the messages, then any subfolders.

* check adding a new IMAP account in debug build. Crashy badness?

* GetOrCreateFolder() in comm/mailnews/base/util/nsMsgUtils.cpp should be renamed to GetOrCreateJunkFolder()

