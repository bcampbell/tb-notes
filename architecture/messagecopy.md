# Assorted notes on copying/moving messages

nsIMsgCopyService is a sort of front end for copying messages about, without worrying too much about the folder types involved.

The copy functions usually support moving too (via a bool param).

can copy/move:

- messages
- file messages (RFC format)
- folders

nsMsgCopyService delegates most of the work to the folder implementations.

Copying is async, uses nsIMsgCopyServiceListener callbacks.

For copying between different nsIMsgIncomingServers, messages must be streamed (ie manually copied).
For operations within the same server, the mailstore might be able to provide
shortcuts (eg maildir can perform moves by just renaming files).

## Example: Copy messages between local folders

### actors involved

`nsMsgCopyService`

  - implements `nsIMsgCopyService`
  - Central point for kicking off copy/move operations.
  - Queues up multiple operations so only one is running at a time.

`nsMsgLocalMailFolder`

  - implements `nsIMsgFolder`
  - implements `nsICopyMessageListener`:

    ```
    void beginCopy();
    void startMessage();
    void copyData(in nsIInputStream aIStream, in long aLength);
    void endMessage(in nsMsgKey key);
    void endCopy(in boolean copySucceeded);
    void endMove(in boolean moveSucceeded);
    ```

`nsICopyMessageStreamListener`

  - provides:

    ```
    void init(in nsICopyMessageListener destination);
    void startMessage();
    void endMessage(in nsMsgKey key);
    void endCopy(in nsIURI uri, in nsresult status);
    ```

  - implements nsIStreamListener (and nsIRequestObserver) to provide:

    ```
    onStartRequest()
    onDataAvailable()
    onStopRequest()
    ```

`nsCopyMessageStreamListener`

  - Implements `nsICopyMessageStreamListener`.
    ```
    void init(in nsICopyMessageListener destination);
    void startMessage();
    void endMessage(in nsMsgKey key);
    void endCopy(in nsIURI uri, in nsresult status);
    ```
  - implements nsIStreamListener (and nsIRequestObserver):
    ```
    onStartRequest()
    onDataAvailable()
    onStopRequest()
    ```
  - Takes a destination `nsICopyMessageListener` to forward calls onto.
  - Calls are mapped like this:
    - `StartMessage()` => call destination `StartMessage()`.
    - `EndMessage(key)` => call destination `EndMessage(key)`.
    - `EndCopy()` => call destination `EndCopy()`.
      If operation was a move, and dest folder is not IMAP, also call
      destination `EndMove()`.
    - `OnStartRequest()` => call destination `BeginCopy()`.
    - `OnStopRequest()` => same as `EndCopy()`.
    - `OnDataAvailable()` => call destination `CopyData()`.

`nsMailboxService`

  - implements `nsIMsgMessageService` (and `nsIMsgMessageFetchPartService`)
  - implements `nsIMsgMessageService` to provide:
    - StreamMessage()
    - CopyMessage() and CopyMessages()
      - These take both a nsIStreamListener and a nsIUrlListener as params
      - It's not really documented, but the implication is that nsIStreamListener
        also needs to implement implement nsICopyMessageStreamListener to handle
        message copy/move.
        I think this is to provide extra functions to indicate where each new
        message starts and ends...

`nsMailboxProtocol`

  - Responsible for running an `nsIMailboxUrl`.
  - Derives from the base nsMsgProtocol class.
    - Provides state machine and async streaming
    - Inherits from nsIChannel, but only as an implementation detail.

### Code flow...

When copying from a local folder into another local folder,
nsMsgCopyService.copyMessages() calls...

`nsMsgLocalMailFolder::CopyMessages()` on the dest folder:

  - Takes a `nsIMsgCopyServiceListener` param. This is for the copy
    operation overall, and shouldn't be confused with other listeners used
    internally: `nsICopyMessageListener` and `nsICopyMessageStreamListener`
    (see nsCopyMessageStreamListener, in CopyMessageTo(), below).
  - Check that all the source messages are available (e.g. if we're offline we
    can't copy messages from IMAP unless we already have offline copies).
  - Check for available diskspace.
  - Try nsIMsgPluggableStore.copyMessages() in case msgStore has a shortcut copy.
     - Some more followup steps if this happens (skipped here).

If we get this far, then got to perform a generic message copy by streaming
messages from the source (this is the "general" case).

  - Turn off message count notifications in the dest folder.
  - Sort src messages by key.
  - Call InitCopyState() to set up a `nsLocalMailCopyState`.
    - Aquire dest folder semaphore.
    - Copy src message list.
    - Copystate `m_listener` is the `nsIMsgCopyServiceListener` which was passed
      in to `nsMsgLocalMailFolder::CopyMessages()`.

  - create a nsParseMailMessageState (for parsing headers of incoming messages)
  - if source isn't a local folder:
    - create a `nsParseMailMessageState`
    - set it to add a "From " line and "X-Mozilla-Status" headers.
    - attach it to the copystate.

  - set up an `nsLocalMoveCopyMsgTxn` to support undo.
  - weird conditional based on copying multiple messages/IMAP...
    - For multiple messages, calls the `CopyMessagesTo()` function.
    - for single message, calls `CopyMessageTo()`.
  - done (if failed, re-enable message count notifications on dest folder).

`nsMsgLocalMailFolder::CopyMessageTo()`

  - Creates an nsCopyMessageStreamListener, passing the dest folder (this) in as a `nsICopyMessageListener`.
  - finds the nsIMsgMessageService for the source message and stores it in the local copystate.
  - calls nsIMsgMessageService.copyMessage()

`nsMailboxService::CopyMessage()/CopyMessages()`:

  - CopyMessage() and CopyMessages() both craft `nsIMailboxUrl` URLs, create
    a `nsMailboxProtocol` object and call `LoadUrl()` upon it, passing the
    nsIStreamListener as the displayConsumer param.
    This all done via nsMailboxService::RunMailboxUrl().
  - The `nsMailboxProtocol` is initialised with the `nsIMailboxUrl`, then
    LoadURL() is called.
  - NOTE: for multiple messages, the message list and current progress is
    maintained on the URL object! see `nsIMailboxUrl.getMoveCopyMsgHdrForIndex()`.

`nsMailboxProtocol::Initialize()`:

  - Faffs about with setting the message size on the URL object. TODO: what
    does it do with multiple messages? Is the size only needed for the
    progress updates?
  - Sets `m_readCount` to the message size.
  - Calls the src folder `GetMsgInputStream()` to access the message.
  - calls nsIStreamTransportService.createInputTransport() to create an
    `nsITransport` around the stream, and stashes it in `m_transport`.
  - `m_transport` is from the base nsMsgProtocol class (which also implements
    a state machine and assorted annoying boilerplate).
  - starts in `MAILBOX_READ_FOLDER` state (but I think this is imediately
      prempted by `LoadUrl()`).

`nsMailboxProtocol::LoadUrl()`:

  - our nsIStreamListener (the `nsCopyMessageStreamListener` we created back
    up in `nsMsgLocalMailFolder::CopyMessageTo()`) is stored as
    `m_channelListener` on the protocol object.
  - it's a copy/move/fetch URL, so the protocol object goes into
    `MAILBOX_READ_MESSAGE` state.
  - the base nsMsgProtocol::LoadUrl() is called:
    - sets `m_channelListener` again (to the same `nsCopyMessageStreamListener`
      we passes in originally :-)
    - opens a (new) inputstream to read from `m_transport`.
    - wraps a `SlicedInputStream` around the stream to restrict the read to
      `m_readCount`, set above.
    - Creates an `nsIInputStreamPump` containing the sliced stream.
    - Starts an `AsyncRead()` from the pump, which kicks off the copy.
    - `this` is passed in to the `AsyncRead()` as the listener (the protocol
      object forwards the data on to the real listener held in m_channelListener).

Phew.
At this point, the message should start flowing, and the protocol object
should start seeing calls to it's nsIStreamListener implementation - 
`OnStartRequest()`, `OnDataAvailable()` and `OnEndRequest()`.

Remembering that our original listener (nsCopyMessageStreamListener) is stashed
in `m_channelListener`, and that the point of that listener is to invoke
`nsICopyMessageListener` methods upon our original dest folder
(nsMsgLocalMailFolder)...

The mailboxprotocol nsIStreamListener callbacks will be called as the data flows:

`nsMailboxProtocol::OnStartRequest()`:

  - call `m_channelListener->OnStartRequest()`.
    - `nsCopyMessageStreamListener::OnStartRequest()`:
      - calls nsMsgLocalMailFolder.BeginCopy()  (from nsICopyMessageListener)
      - ...TODO...

`nsMailboxProtocol::OnStopRequest()`:

  - Lets us know a message has finished.
  - checks the `nsIMailboxUrl` message list and current index.
  - if there are no more messages:
    - set `MAILBOX_DONE` as the next protocol state.
    - call `nsMsgProtocol::OnStopRequest()`:
      - call `m_channelListener->OnStopRequest()`:
        - `nsCopyMessageStreamListener::OnStopRequest()` which just calls
          `EndCopy()` (see below for details)
  - if there are more messages:
    - bump up `nsIMailboxUrl.curMoveCopyMsgIndex`
    - QI `m_channelListener` into `nsICopyMessageStreamListener` and:
      - call `listener->EndCopy()` to indicate a message is done:
        - call `nsCopyMessageStreamListener::EndCopy()`:
          - call `nsMsgLocalMailFolder::EndCopy()`  (from nsICopyMessageListener)
            - ...TODO...
          - if it was a move, then also call `nsMsgLocalMailFolder::EndMove()`
            - ...TODO...
      - call `listener->StartMessage()` to indicate a new message is starting:
        - call `nsCopyMessageStreamListener::StartMessage()`
          - call `nsMsgLocalMailFolder::StartMessage()`
            - ...TODO...

`nsMailboxProtocol::OnDataAvailable()`:

  - not implemented, so `nsMsgProtocol::OnDataAvailable()` is called, which
    just calls nsMailboxProtocol::ProcessProtocolState():
    - we're in `MAILBOX_READ_MESSAGE` state, which just calls
      `nsMailboxProtocol::ReadMessageResponse()`:
      - call `m_channelListener->OnDataAvailable()`.
       - call `nsCopyMessageStreamListener::OnDataAvailable()`
         - call `nsMsgLocalMailFolder::CopyData()`
           - ... TODO ...


SO.
To summarize:
The folder calls the `nsMsgMessageService.CopyMessages()`, passing itself in as
a nsCopyMessageListener.
As the copy proceeds, the folder will see calls to:

- BeginCopy() - at the start of the whole operation
- StartMessage() - at the beginning of each new message (other than the first).
- CopyData() - possibly multiple calls, to transfer the current message data
- EndCopy() - at the end of each message
- EndMove() - in addition to EndCopy(), if the operation is a move.


### NOTES:

 - the nsICopyMessageListener and nsICopyMessageStreamListener are needed
   because the nsMailboxService is streaming out multiple messages in response
   to a single URL.

 - there's a lot more detail on the nsMsgLocalFolder end, not covered here. The
   localcopystate tracks the incoming messages, the output streams and a
   message parser to build a nsMsgDBHeader as the message is received.

 - The implementation of message reading in nsMailboxProtocol is complicated by
   the fact that it handles other operations (eg mbox parsing for folder repair).

 - The nsMailboxProtocol implementation is harder to follow because it inherits
   nsMsgProtocol. I think it could be made a lot simpler if the protocols didn't
   share a base class.



