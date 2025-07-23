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

