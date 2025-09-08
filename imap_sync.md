# IMAP sync notes


```{mermaid}
classDiagram

  class nsIImapOfflineSync {
    <<Interface>>
  }


  nsIImapOfflineSync <|-- nsImapOfflineSync
  nsImapOfflineSync <|-- nsImapOfflineDownloader
```

- nsImapOfflineSync
  - plays back operations that occured while offline.
  - includes folder creation.


- nsImapOfflineDownloader
  - ctor pauses the nsIAutoSyncManager.





## nsIAutoSyncManager


nsAutoSyncManager is a service (i.e. global singleton).

It maintains lists of folders which need attention.


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

### `.onDownloadQChanged()`

- called by nsAutoSyncState::PlaceIntoDownloadQ().




## nsIAutoSyncState

- Implemented solely by nsAutoSyncState.
- Represents one folder in the autosync system
- maintains a message queue: messages in the folder which need downloading.

### States

`stCompletedIdle`
- This state indicates we're idle, nothing happening with this folder right now.
- set in `nsAutoSyncState::OnStopRunningUrl()`, if stStatusIssued completes and there's nothing more needs doing.
- set in `nsAutoSyncManager::OnDownloadCompleted()` if no more pending messages.
- set in `nsAutoSyncManager::StartIdleProcessing()` when removing folders with no pending messages.
- set in `nsAutoSyncManager::AutoUpdateFolders()` 
  - to handle corner case where an update is triggered but there's nothing to download.

`stStatusIssued`
- set from folder, in `nsImapMailFolder::InitiateAutoSync()`

`stUpdateNeeded`
 - set in `nsAutoSyncManager::OnFolderHasPendingMsgs()`,
 - indicates a folder has been added to syncstates updateQ.
 - manager then calls `OnFolderAddedIntoQ()` notification.

`stUpdateIssued`
 - Always set by nsAutoSyncState:
  - in UpdateFolder()
  - in OnStopRunningUrl()
    - to retry updatefolder if counts have changed
    - for some some other icky cornercase

`stReadyToDownload`
- indicates ready to go ahead with download upon next idle time.
- set in nsAutoSyncManager::OnDownloadQChanged()
- set in nsAutoSyncManager::OnDownloadStarted()
  - to try again at next idle, if download failed.
- set in nsAutoSyncManager::OnDownloadCompleted()
  - to keep downloading, while there are pending messages.
- set in nsAutoSyncState::TryCurrentGroupAgain()

`stDownloadInProgress`
- set by nsAutoSyncState::DownloadMessagesForOffline()


### the download queue

- list of messages to download for the folder.
- Fed by:
  - nsAutoSyncState::ProcessExistingHeaders()
    - called by nsAutoSyncManager periodic update to check if messages already in folder need downloading.
  - nsAutoSyncState::OnNewHeaderFetchCompleted()
    - called by imap folder when it's completed fetching headers for the folder.

- cleared in nsIAutoSyncState.resetDownloadQ()

### `PlaceIntoDownloadQ()` (helper)

- called by:
  - `nsAutoSyncState::ProcessExistingHeaders()`
  - `nsAutoSyncState::OnNewHeaderFetchCompleted()`

### .getNextGroupOfMessages()

- used solely by nsAutoSyncManager::DownloadMessagesForOffline().
- Grabs the next batch of messages to download from the queue.
- filters out any messages which:
  - are no longer in the database (might have been deleted)
  - are already stored offline (eg user viewing a message before autosync starts).

### OnNewHeaderFetchCompleted()
- called only from `nsImapMailFolder::HeaderFetchCompleted()`.
- not part of public nsIAutoSyncState interface.
- folder has concrete nsAutoSyncState object.


## nsIAutoSyncMgrListener

onDownloadStarted
onDownloadCompleted




## Papercuts


deCOMtamination:

In nsIAutoSyncManager interface, but only ever called by nsAutoSyncState:
- nsIAutoSyncManager::onDownloadQChanged()
- nsIAutoSyncManager::onDownloadStarted()
- nsIAutoSyncManager::onDownloadCompleted()


- nsAutoSyncManager::DoesMsgFitDownloadCriteria() should be moved into nsAutoSyncState. (only usage is in PlaceIntoDownloadQ()).

SHOULD BE LOCAL:
nsAutoSyncState::Rollback()
nsAutoSyncState::ResetDownloadQ()

nsAutoSyncState::ResetRetryCounter() - used in manager upon failed download at OnDownloadCompleted(). Should be handled internally by the autoSyncState.

UNUSED:
- nsIAutoSyncManager.discoveryQLength
- nsIAutoSyncManager.updateQLength
- nsIAutoSyncManager.downloadQLength

- nsIAutoSyncManager.groupSize

`nsAutoSyncState::ManageStorageSpace()` is do-nothing placeholder.
Probably should ditch it.

DEAD CODE:
- nsIAutoSyncManager.downloadModel never accessed.
- dmParallel download model never used (only dmChained).

possibly dead code?
- folder DownloadMessagesForOffline() functions are only called by msg View, in response to a "Download selected messages". Is this ever exposed?



## Add EWS support


IMAP-specific code in:
- nsAutoSyncManager::TimerCallback()
  - calls nsIMsgImapMailFolder.initiateAutoSync().
    - uses autoSyncManager as listener
- nsAutoSyncManager::AutoUpdateFolders()
  - uses nsIImapIncomingServer.autoSyncOfflineStores
- nsDefaultAutoSyncMsgStrategy::IsExcluded()
  - uses nsIImapIncomingServer.autoSyncMaxAgeDays
- nsAutoSyncState::UpdateFolder()
  - called by nsImapMailFolder::InitiateAutoSync()
  - calls imap UpdateWithListener(), with nsAutoManager as url listener.
nsAutoSyncState::OnStartRunningUrl()
    (use lambda?)
nsAutoSyncState::OnStopRunningUrl()
  - handles finish of IMAP STATUS and FETCH operations.
    (use lambda?)

Remove nsIUrlListener implementation from nsAutoSyncState
 and use lambda listeners?

Ews implementations of:
EwsFolder::InitiateAutoSync()
EwsFolder::UpdateWithListener()


nsAutoSyncState::DownloadMessagesForOffline()

EwsFolder doesn't (yet) have the concept of pending messages (where we know there are messages on the server but we don't yet have the headers).



### Folder -> AutoSync interaction:

nsImapMailFolder knows about concrete nsAutoSyncState class, so can bypass xpcom.

nsImapMailFolder::NotifyHasPendingMsgs() calls:
  - `autoSyncMgr->OnFolderHasPendingMsgs()`
  pending messages are messages we know exist on the server, but we don't have the headers for yet

nsImapMailFolder::InitiateAutoSync() calls:
  - `m_autoSyncStateObj->ManageStorageSpace()`
  - `m_autoSyncStateObj->UpdateFolder()`
  - `m_autoSyncStateObj->SetServerCounts()`
  - `m_autoSyncStateObj->SetState()`
  - `m_autoSyncStateObj->SetLastUpdateTime()`

nsImapMailFolder::HeaderFetchCompleted() calls:
  - `m_autoSyncStateObj->ManageStorageSpace()`
  - `m_autoSyncStateObj->SetServerCounts()`
  - `m_autoSyncStateObj->OnNewHeaderFetchCompleted()` (not part of idl)
