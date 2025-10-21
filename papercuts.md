# Papercuts

Little jobs to tidy up code.


## Remove nsImapCacheStreamListener::mCache2

Kill residual `nsImapCacheStreamListener::mCache2` (no longer needed).
Member var + init params.

## nsImapCacheStreamListener::Peeker()

Don't take a copy of the buffer!

## Comment cruft in `nsIInputStreamListener` (m-c)

Refers to missing param `alistenerContext`

## Kill `Get`/`SetMsgIsInLocalCache()` in URL

Not needed.

## IMAP SendData() should take a nsCString, not char*.

About 60 uses, and all but 10 already convert _from_ nsCString.

## IMAP `GetServerCommandTag()` should return nsCString.

About 50 uses, and all but 3 immediately convert it to nsCString!
Also, could probably calculate string from the `uint32_t` on-the-fly , and kill `m_currentServerCommandTag` member var.


## nsIPop3Sink.beginMailDelivery() doesn't need to return a bool

It's called in 2 places from comm/mailnews/local/src/Pop3Client.sys.mjs and never checked.

## nsIPop3Sink - use proper string types (rather than char ptr)

incorporateWrite() and incorporateBegin() affected. Easy fix.


## kill redundant end-Seek() gubbins in nsPop3Sink::WriteLineToMailbox()

mbox outputstreams don't even support seeking.
also close Bug 1308335


# remove nsMsgLineBuffer and nsByteArray (post D233015)


## Kill nsMailDatabase::Open()

Doesn't add anything to base class. Also inconsistant param names.

## Move nsIMsgFolder.renameSubFolders() out of public interface

[Bug 1947671](https://bugzilla.mozilla.org/show_bug.cgi?id=1947671)


## Inline nsMsgAccountManager::GetLocalFoldersPrettyName()

or at least make it return utf-8


## `const nsCString&` params which should probably be `const nsACString&`

`nsMsgDBFolder`:
  - `CreateCollationKey()`
  - `ConfirmAutoFolderRename()`

## fix winxp ifdef path atrocity in `nsMsgDBFolder::parseURI()`

https://searchfox.org/comm-central/rev/26b7a888cebfce3d3a1bac6dc40a1fea3c76dc52/mailnews/base/src/nsMsgDBFolder.cpp#2896

## Audit use of `AppendRelative[Native]Path()`

Looks like it doesn't handle '/' path separators on windows.
Only used in a couple of places.
Maybe push to remove `nsIFile.appendRelative[Native]Path()` from m-c altogether?

## Tidy up autocompaction decision logic

It's messier and more convoluted than it needs to be.

## Remove nsIMsgFolder.notifyCompactCompleted()

Should just use generic NotifyFolderEvent(kCompactCompleted) instead.

see https://bugzilla.mozilla.org/show_bug.cgi?id=1949605

## Fix or remove "AboutToCompact" folder notification usage.

https://bugzilla.mozilla.org/show_bug.cgi?id=1949609

## Rename/fix IMAP static nsShouldIgnoreFile() helper (clashes with other nsShouldIgnoreFile()).

Only used once.

## modernise NS_MsgGetPriorityFromString()

Should take a nsACString in, and return priority, not error (it's infallible).

## Strip back nsICopyMessageListener()

For each message:
1. BeginCopy()
2. CopyData() as often as needed
3. EndCopy()

startMessage() and endMessage() seem pointless and unused.
endMove() seems very inconsistant. eg Not called for imap -> local

## Kill nsIMsgDatabase.sortNewKeysIfNeeded()

It's silly.

## Get rid of `nsImapMailFolder::m_filterList`.

unnecessary duplication - it's held in nsIMsgIncomingServer.

## Remove PLDHashTable use

- nsMsgDatabase headercache (Bug 1417018)
- nsBayesianFilter.cpp


## remove nsMsgIncomingServer::mFilterPlugin

See GetSpamFilterPlugin().
Uses `do_GetService()` - it's a singleton?

## remove nsIJunkMailPlugin.classifyTraitsInMessage()

Only used in tests.
Use classifyTraitsInMessages() instead?

## remove nsIJunkMailPlugin.classifyMessages()?

unused.
Could also simplify MessageClassifier? (underlying mechanism)


## Get rid of `aGenerateDummyEnvelope` param in `nsIMsgMessageService.saveMessageToDisk()`

Might get a bit involved... but shouldn't be needed.
The only case where is _could_ be needed would be when appending to an mbox, saveMessageToDisk() almost certainly doesn't do From- quoting, so will be useless for that task anyway!

## nsIMsgFilterList.idl + nsMsgFilterList

- Add `readonly Array<nsIMsgFilter> filters`.
- Ditch the cumbersome filterCount/getFilterAt().
- Ditch setFilterAt() (only used internally).

## nsIMsgFilter.getCustomAction() can fail if custom actions aren't initialised.

- stupid api.

## "FiltersApplied" FolderEvent never used? Remove?

grep for "FiltersApplied"

## Inline nsMsgDBFolder::(Start|End)NewOfflineMessage() in IMAP and news.

Not used anywhere else.
Also means we can ditch `nsMsgDBFolder` members:

- `m_tempMessageStream`
- `m_tempMessageStreamBytesWritten`
- `m_numOfflineMsgLines`
- `m_bytesAddedToLocalMsg`

## rename nsIImapMessageSink.parseAdoptedMsgLine() aAdoptedMsgLine param

- it's used for any number of lines.

## remove nsIImapMessageSink.parseAdoptedMsgLine() aImapUrl param

- it's not used/needed.

## ditch appendDummyEnvelope in setupMsgWriteStream().

- used by template saving (mailbox: protocol)... but probably shouldn't be?
- also ditch nsIMsgMailNewsUrl.AddDummyEnvelope attr


## nsIMsgFolder.downloadMessagesForOffline() is dead code?

- folder DownloadMessagesForOffline() functions are only called from nsMsgDBView, in response to a "Download selected messages". Is this ever exposed?
- the autosync stuff uses nsIImapService.downloadMessagesForOffline().
- nsImapMailFolder::DownloadMessagesForOffline() just calls nsIImapService.downloadMessagesForOffline(), but wraps it with a semaphore.

## Usused nsIMsgBiffManager.forceBiff() and forceBiffAll()

## Better comments on EwsIncomingServer::Sync* functions

