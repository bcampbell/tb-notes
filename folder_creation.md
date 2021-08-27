# Folder Creation functions

## IMAP notes

`nsImapProtocol` calls `m_imapServerSink->PossibleImapMailbox()` when a folder
is discovered.


## nsIMsgFolder

```
  /**
   * Create a subfolder of the current folder with the passed in name.
   * For IMAP, this will be an async operation and the folder won't exist
   * until it is created on the server.
   *
   * @param folderName name of the folder to create.
   * @param msgWindow msgWindow to display status feedback in.
   *
   * @exception NS_MSG_FOLDER_EXISTS
   */
    void createSubfolder(in AString folderName, in nsIMsgWindow msgWindow);
```
- async on IMAP
- unimplemented in nsMsgDBFolder
- implemented by nsImapMailFolder, nsMsgLocalMailFolder, nsMsgNewsFolder
- in nsMsgLocalMailFolder:



```
 /**
   * Adds the subfolder with the passed name to the folder hierarchy.
   * This is used internally during folder discovery; It shouldn't be
   * used to create folders since it won't create storage for the folder,
   * especially for imap. Unless you know exactly what you're doing, you
   * should be using createSubfolder + getChildNamed or createLocalSubfolder.
   *
   * @param aFolderName Name of the folder to add.
   * @returns The folder added.
   */
    nsIMsgFolder addSubfolder(in AString aFolderName);
```

- implemented by nsMsgDBFolder and nsImapMailFolder
- nsMsgDBFolder version:
  1. sanitise name (urlencode)
  2. tweak names if creating under root folder (eg "inbox" -> "Inbox")
  3. check existance (returns `NS_MSG_FOLDER_EXISTS`)
  4. child = CreateChildFromURI()   (which calls Init())
  5. child.SetParent(parent)
  6. set some flags for special folder names (biffstate, trash etc)
  7. parent.subFolders.Append(child)

```
  /* this method ensures the storage for the folder exists.
    For local folders, it creates the berkeley mailbox if missing.
    For imap folders, it subscribes to the folder if it exists,
    or creates it if it doesn't exist
  */
  void createStorageIfMissing(in nsIUrlListener urlListener);
```









## misc

nsIMsgFolder createChildFromURI(in ACString uri);



# nsIMsgPluggableStore

```
  /**
   * Examines the store and adds subfolders for the existing folders in the
   * profile directory. aParentFolder->AddSubfolder is the normal way
   * to register the subfolders. This method is expected to be synchronous.
   * This shouldn't be confused with server folder discovery, which is allowed
   * to be asynchronous.
   *
   * @param aParentFolder folder whose existing children we want to discover.
   *                      This will be the root folder for the server object.
   * @param aDeep true if we should discover all descendents. Would we ever
   *              not want to do this?
   */

  void discoverSubFolders(in nsIMsgFolder aParentFolder, in boolean aDeep);
```

```
  /**
   * Creates storage for a new, empty folder.
   *
   * @param aParent parent folder
   * @param aFolderName leaf name of folder.
   * @return newly created folder.
   * @exception NS_MSG_FOLDER_EXISTS If the child exists.
   * @exception NS_MSG_CANT_CREATE_FOLDER for other errors.
   */
  nsIMsgFolder createFolder(in nsIMsgFolder aParent, in AString aFolderName);
```

