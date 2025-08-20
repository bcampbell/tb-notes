# IMAP sync notes


```{mermaid}
classDiagram

  class nsIImapOfflineSync {
    <<Interface>>
  }


  nsIImapOfflineSync <|-- nsImapOfflineSync
  nsImapOfflineSync <|-- nsImapOfflineDownloader
```


- nsImapOfflineDownloader
  - ctor pauses the nsIAutoSyncManager.

- nsImapOfflineSync
  - plays back operations that occured while offline.
  - includes folder creation.



```{mermaid}
classDiagram

  class nsIAutoSyncManager {
    <<Interface>>
    msgStrategy nsIAutoSyncMsgStrategy
    folderStrategy nsIAutoSyncFolderStrategy
  }

  nsIAutoSyncManager <|-- nsAutoSyncManager 


  note for nsIAutoSyncMgrListener "Implemented by autosync.sys.mjs\nfor activity mgr"

  class nsIAutoSyncMgrListener {
    <<Interface>>
  }

  class nsIAutoSyncState {
    <<Interface>>
  } 

  nsIAutoSyncState <|-- nsAutoSyncState


  class nsIAutoSyncFolderStrategy {
    <<Interface>>
  } 

  nsIAutoSyncFolderStrategy <|-- nsDefaultAutoSyncFolderStrategy

  class nsIAutoSyncMsgStrategy {
    <<Interface>>
  } 

  nsIAutoSyncMsgStrategy <|-- nsDefaultAutoSyncMsgStrategy
```

- no Strategy implementations other than the default ones

