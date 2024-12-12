
## POP3 protocol quick reference

Quick POP3 command summary (ignoring auth):

```
STAT - returns msg count and total size (deleted messages are excluded)
LIST [msg] - return "{msg} {size}" pair for {msg}, or for all (non-deleted) messages if no arg given.
RETR msg - fetch message {msg}
DELE msg - delete message {msg}
RSET - unmark all deleted messages
NOOP
UIDL [msg] - return "{msg} {uidl}" pair for {msg}, or for all (non-deleted) messages if no arg given.
TOP msg n - return headers and first {n} lines of {msg}
```

UIDLs are:
- Server-assigned unique IDs.
- ASCII strings, 70 chars max, valid chars are 0x21-0x7E.
- Persistant between sessions.
- UIDL support is optional, but probably very rare to be missing.
- Protocol still uses per-session message numbers for interactions.
- We store UIDL in messsage header X-UIDL and popstate.dat (but not in DB?).

I don't think UIDL is stored in the DB at all...

If message is larger than a threshold, then TOP will be used to download just the headers and first few lines.
Otherwise whole message will be downloaded with RETR.


## popstate.dat

Persists the list of UIDLs the client knows of.

File format:

Comment lines begin with '`#`'.

Lines beginning with '`*`' denote host and user:
```
*localhost bob
```

Other lines have format {status} {uidl} {timestamp}, where status is:

```
k = keep
d = delete
b = too big (headers only, and perhaps a few lines of body)
f = want to fetch body
```

e.g.

```
k 1730938639.M5937P117090.howl,S=280,W=289 1732586776
```

TODO: is popstate.dat a list of all the messages in the db?
i.e. should we just use the db instead?


## nsPop3Sink

PopSink is the interface that the protocol uses to talk to the folder, mostly to deliver messages.
Unlike IMAP sink interfaces, which are directly implemented by the IMAP folder, `nsPop3Sink` is a separate object which talks to a `nsMsgLocalMailFolder`.
The `nsPop3Sink` object  is owned by the `nsPop3URL`.
Instead of deriving from `nsIPop3Sink`, `nsLocalMailFolder` gets the sink from the URL, in `nsLocalMailFolder::OnStartRunningUrl()`.

### `nsIPop3Sink` interface

```
interface nsIPop3Sink : nsISupports {

  attribute boolean buildMessageUri;
  attribute AUTF8String messageUri;
  attribute AUTF8String baseMessageUri;

  /// message uri for header-only message version
  attribute AUTF8String origMessageUri;

  boolean beginMailDelivery(in boolean uidlDownload, in nsIMsgWindow msgWindow);
  void endMailDelivery(in nsIPop3Protocol protocol);
  void abortMailDelivery(in nsIPop3Protocol protocol);

  void incorporateBegin(in string uidlString, in unsigned long flags);
  void incorporateWrite(in string block, in long length);
  void incorporateComplete(in nsIMsgWindow aMsgWindow, in int32_t aSize);
  void incorporateAbort();

  void setMsgsToDownload(in unsigned long aNumMessages);

  void setBiffStateAndUpdateFE(in unsigned long biffState, in long numNewMessages, in boolean notify);

  attribute nsIPop3IncomingServer popServer;
  attribute nsIMsgFolder folder;
};

```

### nsPop3Sink::BeginMailDelivery()

Sets up to pass messages to the folder:

1. Locks the folder
2. if uidlDownload is false, fetches UIDLs for all partial messages in the msgStore (see [Bug 1933575](https://bugzilla.mozilla.org/show_bug.cgi?id=1933575))
3. stashes the number of new messages currently in the folder
4. calls pop3Service.NotifyDownloadStarted()


### nsPop3Sink::IncorporateBegin()

1. Asks the msgStore for a new output stream, saves in `m_outFileStream`.
2. Creates a nsParseNewMailState object (copying a few fields over from a previous one if multiple messages are being delivered)
3. maybe tell the parser to disable filters (if downloading a single message?)
4. write out some extra headers: `X-Account-Key`, `X-UIDL:`, `X-Mozilla-*` etc

### nsPop3Sink::IncorporateWrite()

Used to write both full messages (via RETR) and partial messages (via TOP).

Called with a single line at a time.

Just passes each line to the `nsParseNewMailState` parser, and writes it to `m_outFileStream`.

### nsPop3Sink::IncorporateComplete()

1. Set the nsIPop3Sink.messageUri attr.
2. (bug workaround) Send a blank line to the parser to kick it into correct state.
3. Flush the output stream.
4. Reconciles the new message with any already existing one (header-only/partial)
5. Call `FinishNewMessage()` on the msgStore, to commit it.
6. Call `parser->PublishMsgHeader()`, then `parser->ApplyForwardAndReplyFilter()`.
    - PublishMsgHeader() applies filter rules
7. if there was a partial message which we're replacing with the full one:
    1. Delete the old header from the DB
    2. Send out a "message-content-updated" event. This is the only place in the code that sends "message-content-updated".
8. Update the download progress. (`pop3Service->NotifyDownloadProgress()`).

### nsPop3Sink::IncorporateComplete()

Basically just calls `m_msgStore->DiscardNewMessage()` to roll back.

 
## `nsParseNewMailState` use by nsPop3Sink:


nsPop3Sink::CheckPartialMessages() calls:
 DeleteHeader()


nsPop3Sink::EndMailDelivery() calls:

 OnStopRequest()
 EndMsgDownload()
 UpdateDBFolderInfo()
 GetMsgWindow()a (to determine if filter plugin should be run)

nsPop3Sink::AbortMailDelivery() calls:
 UpdateDBFolderInfo()


nsPop3Sink::IncorporateBegin() calls:
 reads out `m_numNotNewMessages` and `m_moveCoalescer` and `m_filterTargetFoldersMsgMovedCount`
 creates the new `nsParseNewMailState` (stashes it in `nsPop3Sink::m_newMailParser`)
 reinstates the various saved fields
 DisableFilters() (if `nsPop3Sink::m_uidlDownload` is set)
 calls nsPop3Sink::WriteLineToMailbox() a few times for custom headers

nsPop3Sink::IncorporateWrite() calls:
 just calls nsPop3Sink::WriteLineToMailbox()


nsPop3Sink::WriteLineToMailbox() calls:
 HandleLine()

nsPop3Sink::IncorporateComplete() calls:
 gets header from `m_newMsgHdr`
 HandleLine("") (LF hack)
 PublishMsgHeader()
 ApplyForwardAndReplyFilter()

nsPop3Sink::IncorporateAbort()
 accesses `m_newMsgHdr` but just for discarding the msgStore stream.


nsPop3Sink::SetBiffStateAndUpdateFE()
 accessed `m_numNotNewMessages`.




