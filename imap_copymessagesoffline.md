# Notes on `nsImapMailFolder::CopyMessages()`

## Case 1: Online, and copying messages between IMAP folders on same server.

If we're online, and it's copying between folders on the same server, CopyMessages() will:

1. Call `CopyMessagesOffline()` (see below). This will do a local copy and set up offline copy operations.
2. Kick off a 500ms timer, which calls `nsImapMailFolder::PlaybackTimerCallback`.
   This runs an nsImapOfflineSync() object, which plays back the offline operations upon the source folder.
   This starts the corresponding IMAP operations.

Then, as the messages appear in the IMAP mailbox, the folder will be notified.
These "new" messages from IMAP are then reconciled with the provisional messages from the local copy.
IMAP passes incoming messages to the folder via `nsImapMailFolder::ParseMsgHdrs()`.

Looks like it's done this way to provide immediate user feedback.


### `nsImapMailFolder::CopyMessagesOffline()`.

See also [Bug 1873282](https://bugzilla.mozilla.org/show_bug.cgi?id=1873282).

- internal helper fn, not used outside nsImapMailFolder

Steps performed:

1. Call `txnMgr->BeginBatch(nullptr)`
2. Find unused range of msgKeys in the dest DB to use as "fake" keys for the incoming messages. 
   Store first free msgKey in `fakeBase`.
3. use BuildIdsAndKeyArray() to generate a UID range string (messageIds) from the src message keys (which really are UIDs)
4. disable message count notifications on dest folder
5. For each src message:
  1. Get or create offline op in the sourceDB (message might already be the subject of some offline operation!)
  2. Set the nsMsgFolderFlags::OfflineEvents flag on the source folder.
  3. Jump through hoops to handle case of message being the result of an offline move... (glossing over that case here).
  4. Add the destination folder to the offline op.
  5. Create a new msgHdr in the dest DB, using `CopyHdrFromExisingHdr()` to copy the hdr in the src DB (addHdrToDB is true).
  6. Set the `pseudoHdr` property upon the dest msgHdr.
  7. If there's an offline copy of the full message in the messageStore, copy it.
     Else just mark the message as "not offline" (`database->MarkOffline(key,false);`)
  8. Get or create offline op in dest DB, adding the src folder and src msgKey.
6. reenable message count notifications on dest folder
7. Create an `nsImapOfflineTxn` object to represent the copy (`addHdrMsgTxn`).
   Txn type is nsIMsgOfflineImapOperation::kAddedHeader.
8. Call `txnMsg->DoTransaction()` to execute the `addHdrMsgTxn` (Red herring. `nsImapOfflineTxn::DoTransaction()` is a no-op!).
9. Create another `nsImapOfflineTxn` to handle undo (`undoMsgTxn`).
10. Call `txnMgr->DoTransaction(undoMsgTxn)` (Red herring. `nsImapOfflineTxn::DoTransaction()` is a no-op).
    NOTE: should handle operation and it's undoing in a single transaction, not seperately!
11. Perform a commit on the dest DB (src DB is only committed for move operation).
12. Call SummaryChanged() on both dest and src folders
13. Call `txnMgr->EndBatch()`.
14. If any messages were copied, invoke `nsIMsgFolderNotificationService.notifyMsgsMoveCopyCompleted()`
15. Tell the copy service that a copy has completed (although presumably any IMAP copy operation is still in flight).



