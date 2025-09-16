# AutoSync Manager notes


There's a global nsIAutoSyncManager service which handles downloading messages for offline use.
It also can perform periodic checks for new messages.

You can log its activity with `MOZ_LOG="IMAPAutoSync:5"`.

It maintains a prioritised queue of folders that need checking/downloading.
For each folder it maintains a prioritised list of messages which need downloading.

It takes actions in response to:
- new messages arriving i.e. the folder has downloaded new message headers and added them to the database.
- a periodic timeout
- idle times

The actions it can perform:
- check with the server to see if a folder has new messages
- tell the folder to fetch new messages from the server
- download a batch of messages to add to the local message store for offline use.
  - the batches are decided based on a size threshold.

The folder state is represented by `nsIAutoSyncState`.
Each folder which wants to participate in AutoSync provides an `nsIAutoSyncState` object and registers it with the `nsIAutoSyncManager`.

NOTE: don't get the AutoSync interfaces mixed up with `nsIImapOfflineSync` and `nsImapOfflineDownloader`.
Those are red herrings, concerned with playing back operations that occurred on IMAP folders while offline.

## Implementation

The two concrete C++ classes are `nsAutoSyncManager` and `nsAutoSyncState`.

They are pretty tightly coupled, and a lot of the interface methods are concerned with coordinating with each other, which makes using them quite confusing.

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


### nsIAutoSyncManager

`.onDownloadQChanged()`
  - called by nsAutoSyncState::PlaceIntoDownloadQ().


### nsIAutoSyncState

- Implemented solely by nsAutoSyncState.
- Represents one folder in the autosync system
- maintains a message queue: messages in the folder which need downloading.

#### States

`stCompletedIdle`
- This state indicates we're idle, nothing happening with this folder right now.
- set in `nsAutoSyncState::OnStopRunningUrl()`, if stStatusIssued completes and there's nothing more needs doing.
- set in `nsAutoSyncManager::OnDownloadCompleted()` if no more pending messages.
- set in `nsAutoSyncManager::StartIdleProcessing()` when removing folders with no pending messages.
- set in `nsAutoSyncManager::AutoUpdateFolders()` 
  - to handle corner case where an update is triggered but there's nothing to download.

`stStatusIssued`
- Set by `nsImapMailFolder::InitiateAutoSync()`.
- This state indicates that we've issued a STATUS (or NOOP for selected fmailbox) and are waiting for results.
  - this updates the Total, Unseen and Recent message counts for the nsImapMailFolder (as well as NextUID etc).
  - It's not clear what "Recent" messages are.
- when the STATUS completes, nsAutoSyncState::OnStopRunningUrl() handles it
  - if the total or recent counts (or nextUID) are unchanged, go back into `stCompletedIdle` state.
  - if counts have changed, call UpdateFolder() and go straight into the `stUpdateIssued` state.

`stUpdateNeeded`
 - Indicates a folder has been added to syncstates updateQ.
 - Set by `nsAutoSyncManager::OnFolderHasPendingMsgs()`,
 - Manager then calls `OnFolderAddedIntoQ()` notification.

`stUpdateIssued`
 - Indicates that an UpdateFolder() is in progress.
    - i.e. we're downloading message headers.
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


#### the download queue

- list of messages to download for the folder.
- Fed by:
  - nsAutoSyncState::ProcessExistingHeaders()
    - called by nsAutoSyncManager periodic update to check if messages already in folder need downloading.
  - nsAutoSyncState::OnNewHeaderFetchCompleted()
    - called by imap folder when it's completed fetching headers for the folder.

- cleared in nsIAutoSyncState.resetDownloadQ()

#### Assorted functions:

`PlaceIntoDownloadQ()` (helper)

- called by:
  - `nsAutoSyncState::ProcessExistingHeaders()`
  - `nsAutoSyncState::OnNewHeaderFetchCompleted()`

`.getNextGroupOfMessages()`

- used solely by nsAutoSyncManager::DownloadMessagesForOffline().
- Grabs the next batch of messages to download from the queue.
- filters out any messages which:
  - are no longer in the database (might have been deleted)
  - are already stored offline (eg user viewing a message before autosync starts).

`.OnNewHeaderFetchCompleted()`
- called only from `nsImapMailFolder::HeaderFetchCompleted()`.
- not part of public nsIAutoSyncState interface.
- folder has concrete nsAutoSyncState object.


### nsIAutoSyncMgrListener

I think this is mainly used to drive the activity manager in the GUI, so the status bar shows something when autosync operations are in progress...

See `autosync.sys.mjs`.

`.onDownloadStarted()`

`.onDownloadCompleted()`
- called by nsAutoSyncState at end downloading a batch.
  - it'll decide what to download next? Confirm!

## Papercuts

deCOMtamination:

In nsIAutoSyncManager interface, but only ever called by nsAutoSyncState:
- nsIAutoSyncManager::onDownloadQChanged()
- nsIAutoSyncManager::onDownloadStarted()
- nsIAutoSyncManager::onDownloadCompleted()


- nsAutoSyncManager::DoesMsgFitDownloadCriteria() should be moved into nsAutoSyncState. (only usage is in PlaceIntoDownloadQ()).
  - should just call `folder->ShouldStoreMsgOffline()` instead.
  - Should merge nsMsgDBFolder::MsgFitsDownloadCriteria() and ShouldStoreMsgOffline().


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

- nsAutoSyncState::DownloadMessagesForOffline() and nsAutoSyncState::GetNextGroupOfMessages() are only ever called from 
nsAutoSyncManager::DownloadMessagesForOffline()?
  - combine, simplify...


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



## Folder -> AutoSync interaction:

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
