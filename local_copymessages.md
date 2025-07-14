# Notes on nsMsgLocalFolder::CopyMessages()

All incoming messages are from same source folder.


Check that there's (roughly) enough space on local filesystem.

If we're offline and copying from an IMAP or News folder, make sure there's a local offline copy of the message.

Call msgStore.copyMessages() in case there's a shortcut.
  - maildir does the copy and we exit.
  - mbox refuses, and requires us to do it the hard way.

Turn off message count notifications (they'll be updated in one go at the end).

Sort messages by key.

Call InitCopyState()

 - Self-lock the folder
 - Create a new nsLocalMailCopyState (mCopyState) and set it up.
   - `m_srcSupport` is source folder
   - `m_messages` is array of nsIMsgDBHdrs
   - `m_curCopyIndex` is index of current message being copied
   - `m_copyingMultipleMessages` is false?
   - `m_listener` is nsIMsgCopyServiceListener passed into CopyMessages()

If protocol is _not_ "mailbox":

   - set mCopyState flag to add X-Mozilla- headers
   - `mCopyState->m_parseMsgState = new nsParseMailMessageState`
   - WTF: what parses messages if not "mailbox" protocol.

Set up an undo msgTxn if undo support was requested.

if copying multiple messages
   AND (imap AND not all messages available offline)
   OR protocol == "mailbox":

   `mCopyState->m_copyingMultipleMessages = true;`
   Call CopyMessagesTo()
else:

   Call CopyMessageTo() with header of the message.

Return. Operation is async.

## nsMsgLocalFolder::CopyMessageTo()

Kicks off a copy of an individual message to this folder.

`streamListener = new CopyMessageStreamListener();`

Gets the msgService from the message URI.

`mCopyState->m_messageService = msgService;`

`msgService->CopyMessage(uri, streamListener, isMove, nullptr /* urlListener */, window);`

return.

## nsMsgLocalFolder::CopyMessagesTo()

Kicks off a copy of multiple messages to this folder.

`streamListener = new CopyMessageStreamListener();`

Gets the msgService from the message URI.

`mCopyState->m_messageService = msgService;`

`msgService->CopyMessages(msgKeys, srcFolder, streamListener, isMove, nullptr /* urlListener */, window);`

CopyMessages() does return a URI representing the operation, but it's ignored here.
We are also passing in a null urlListener (which we'd normally use to determine when it was finished) - the streamListener handles the whole lifecycle.

return.

## `CopyMessageStreamListener`

Implements nsIStreamListener and nsICopyMessageListener.
Used by local folders, EWS, IMAP.

Passes through all the nsICopyMessageListener callbacks to the underlying object, except for EndCopy().
On non-IMAP folders it also calls EndMove() ifisMove is set.

OnStartRequest() invokes BeginCopy()

OnStopRequest() invokes EndCopy()


## Once the copy has been kicked off

Callbacks are called on the folder (which passed itself in as the `nsICopyMessageListener`

nsMsgLocalFolder::BeginCopy()






