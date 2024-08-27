# Notes on `nsImapMailFolder::CopyMessages()`


nsImapMailFolder::CopyMessages() is used to copy messages into the imap folder - `this` is the destination folder.


## Case 1: Online, and copy/move messages between IMAP folders on same server.

If we are: online, copying between folders on the same server, and undo is allowed (i.e. it's a user-initiated operation rather than, say, a filter action), then CopyMessages() will:

1. Call `CopyMessagesOffline()` (see below). This will do a local copy and set up offline copy operations.
2. Kick off a 500ms timer, which calls `nsImapMailFolder::PlaybackTimerCallback`.
   This runs an nsImapOfflineSync() object, which plays back the offline operations upon the source folder.
   The nsImapOfflineSync() is set up with isPseudoOffline=true, and no nsIUrlListener.
   This starts the corresponding IMAP operations.

Then, as the messages appear in the IMAP mailbox, the folder will be notified.
These "new" messages from IMAP are then reconciled with the provisional messages from the local copy.
IMAP passes incoming messages to the folder via `nsImapMailFolder::ParseMsgHdrs()`.

Looks like it's done this way to provide immediate user feedback.

TODO: write notes on nsImapOfflineSync().

## Case 2: We're offline. Copying from any source server.

The messages are sorted by key order (why?) and then CopyMessagesOffline() is called.
That's it.

TODO: does that mean undo operations are added for filter-driven actions on offline folders?


## Case 3: Copying messages from another server

1. Messages are sorted by key order.
2. SetPendingAttributes() (see below) is called on the messages.
3. CopyMessagesWithStream() is called.
4. Done.

## Case 4: Copying messages from same server

1. Messages are sorted by key order.
2. SetPendingAttributes() (see below) is called on the messages.
3. Set up a copystate object on the folder
4. Call imapService `OnlineMessageCopy()` with the UIDs of the messages to copy
   - folder itself is the urlListener for the OnlineMessageCopy(), so when it's done, the folders OnStopRunningUrl() will be called.
5. set up an `nsImapMoveCopyMsgTxn` on the copystate (if not filter-initiated)

When the OnlineMessageCopy() finishes, the imap folder OnStopRunningUrl() is called, and will:

1. call NotifyMsgsMoveCopyCompleted()
2. 


### `nsImapMailFolder::SetPendingAttributes()`/`UpdatePendingAttributes()`

This is the mechanism which allows local message-copy operations to be performed immediately, and be resolved later when the server-side operation finally completes.

Given a msgHdr, this functions creates a new row in the pendingHdrs table in the db, indexed by the Message-Id.

It then copies the properties of the msgHdr into the new row.
There are a few exceptions - not all properties should be copied, addons can specify properties to avoid and there's a little hoop-jumping to handle numeric properties.
But in general, you end up with a copy of the msgHdr in the pendingHdrs table.

Later on, when a new message is added to the IMAP database (see `nsImapMailDatabase::AddNewHdrToDB()`), its Message-Id is looked up in the pendingHdrs table and the values are copied into the new header. The pendingHdr row is then discarded.

`nsImapMailDatabase::UpdatePendingAttributes()` handles that lookup and property-copying.

`UpdatePendingAttributes()` is called from `nsImapMailDatabase::AddNewHdrToDB()` and from `nsParseMailMessageState::FinalizeHeaders()` (nsParseMailbox.cpp), which is where raw message headers are parsed into msgHdrs.

`setPendingAttributes()` and `updatePendingAttributes()` are part of the `nsIMsgDatabase` interface, but are only implemented in `nsImapMailDatabase` - the base versions are just no-ops, returning `NS_OK`.


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


### nsImapOfflineSync

nsImapOfflineSync is set up with an Init() call, then kicked off by calling ProcessNextOperation().

It's insanely complex, but basic upshot is that it iterates through offline ops in the folder, and calls either `imapFolder->ReplayOfflineMoveCopy()` (for same-server moves and copies) or `msgCopyService->CopyMessages()` for cross-server operations.

For both methods, it passes itself as the listener (as a nsIUrlListener for the same-server case, or nsIMsgCopyServiceListener for the cross-server case).

So when each operation finishes, the OnStopRunningUrl() handler kicks off the next one (if any).





