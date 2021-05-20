# Major cleanups

# TB-specific `nsIChannel` usage

The TB protocols (eg `nsNNTPProtocol`, etc) implement the standard mozilla
`nsIChannel`/`nsIRequest` interfaces, but then bypass them and tie in
all sorts of other stuff (eg `nsNtntpIncomingServer::LoadNewsUrl()`).
There's a lot of complication in there.

-> refactor to be more "pure" protocols. Use firefox as example.

# TB-specific URL classes add lots of state

The `nsIURI`-derived classes in TB add lots of request-specific
concepts. They add listeners and track request state etc...

-> URI objects should just be URIs. Protocol-specific classes can add
utility fns to set/extract protocol-specific fields, but that should be
about it.

-> should be able to move all the listener/state out, because we're
using `nsIChannel`-based objects to run requests already, right?

# Make folder creation/renaming/deleting etc async.

It needs to be async for IMAP, so use the same API for the other folder types.
Will simplify things a lot. Doesn't make things less responsive as the
listeners can just be directly invoked when possible.
Applies to message operations too (move/copy/delete messages etc)

# Folder creation: ditch the requirement for dangling folders.

As a byproduct of the now removed RDF code, we still rely on being able
to get folders which have not yet been created. This is bonkers.
Rationalise the folder creation paths, so that folders are always constructed
in predictable ways!

# ditch XPCOM for things which are implemented only in C++

see also: https://wiki.mozilla.org/Gecko:DeCOMtamination

benefit:
- simplification
- more idiomatic C++ (less QueryInterface and nsresult checking)
- better encapsulation (can better choose what to expose to JS)
- easier debugging (eg see member vars for base classes)
- more optimisation opportunity for compiler (inlining etc)

eg: The folder classes.
Expose to JS via a very specific, JS-centric interface.

What is firefox policy on this these days?

# nail down nsIMsgPluggableStore responsibilities

Ideally should just deal with filesystem, but needs to stash things in the
message database (eg offsets of messages within an mbox file).
Figure out a good interface boundary.
Ideally, pluggable mailstores shouldn't know anything about folders.

# nail down naming policies

The UI-facing names aren't always the same as filesystem names.
- There are localisation hacks.
- Case-insensitivity is an issue on windows.
- Some folder flags are set by name?
- IMAP has some special rules

It'd be nice to collect all the policy into one place (probably
plugablemailstore, which should really be the only part dealing with
filenames).
At the moment, such hacks are spread all over the place.

see places in code:

    nsMsgDBFolder::AddSubfolder()  (forcing case on certain folders)


# Gradual move away from wide strings (UCS-2/UTF-16) in C++

Start phasing out use of 16-bit strings on the C++ side?

idl files: use AUTF8String instead of AString.
C++: use nsCString (8bit) instead of nsString (16bit)
javascript: no change (AUTF8String Just Works (tm))

Prime candidates to swap over in nsIMsgFolder: name, prettyName,
abbreviatedName etc..


# Smaller stuff

## nsMsgDBFolder has IMAP-specific undelete support

Currently nsMsgDBFolder has special IMAP paths for dealing with mark-as-delete.
Should promote mark-as-deleted to general folder capability.

## nsIMsgFolder::incomingServerType could be ditched?

If every folder has a server (which does seem to be the case with
folder-lookup-service), incomingServerType uses should be replaced by:

    folder->GetServer()->GetType();

or something.

Not many usages:

    $ grep -ri incomingServerType comm


## unify OnMessageClassified() handlers

nsImapMailFolder::OnMessageClassified() and
nsMsgLocalMailFolder::OnMessageClassified() seem to do the same thing, but
the imap one uses a move coalleser to perform the move async.
Should convert the local folder to also be async, and use the same code.

## nsMsgIncomingServer::GetMsgFolderFromURI() is bonkers

first param, folderResource, is redundant.


## CreateStorageIfMissing() is misleading name

nsMsgLocalMailFolder::CreateStorageIfMissing() at least seems
entirely concerned with linking up dangling folders...

## CreateStorageIfMissing() - delete altogether?

used by only 2 fns in C++:

- GetOrCreateJunkFolder()
- nsMsgCopy::CreateIfMissing()

and in javascript:

- comm/mail/base/content/mailCommands.js
- comm/mail/base/content/mailWindowOverlay.js
- comm/mailnews/imap/test/unit/test_saveTemplate.js
- comm/mail/test/mozmill/folder-pane/test-folder-pane.js


## special case handling for junk folder localized name

The default junk folder is supposed to be called "Junk" on disk, but
appear in the UI with a (potentially) localized name.
There's a little special-case handling in msgUtils.cpp 
GetOrCreateJunkFolder(), resulting from Bug 270261
    https://bugzilla.mozilla.org/show_bug.cgi?id=270261

It seems like this issue extends to other folder types?
Shouldn't there be a generalised mechanism to handle it?


## nsMsgDBFolder::VerifyOfflineMessage() not used?

Doesn't ever seem to be referenced.
Looks for "From -" line, which is dodgy...

  $ grep -ir VerifyOfflineMessage comm

## unify nsIMsgFolderListener and nsIFolderListener?

nsIFolderListener was retained to avoid breaking extensions.


## nsMsgAccountManager::SetSpecialFolders() only used by PostAccountWizard()

It looks SetSpecialFolders() is only ever used by LoadPostAccountWizard()
in mail/base/content/msgMail3PaneWindow.js.

    $ cd comm
    $ grep -ir SetSpecialFolders *

## factor out folder flag policy?

see:
mailnews/base/src/nsMsgAccountManager.cpp nsMsgAccountManager::SetSpecialFolders() 

## TB protocols - set context param to nullptr.

nsMsgProtocol-derived protocols should always send nullptr to
stream callbacks to avoid any code relying on it.

see [Bug 1525319 - Investigate if we can remove Context argument from Channel methods](https://bugzilla.mozilla.org/show_bug.cgi?id=1525319)

## TB protocols - audit URI use in streamlistener callbacks

OnStartRequest et al shouldn't cast request param to channel.
(exception might be OnDataAvailable(), which is a channel-specific callback).
Some TB code relies on this, and it shouldn't.

## separate nsParseMailMessageState out from nsMsgMailboxParser?

nsMsgMailboxParser is parser for mbox files.
nsParseMailMessageState is used by mbox, maildir (and imap, more?).

## nsICopyMessageStreamListener::EndCopy() uri param shouldn't be type nsISupport

Why shouldn't it be a proper URI type?

## nsNntpIncomingServer::GetNntpChannel() should take loadInfo as param?

Currently all callers have to manually set the loadInfo attr themselves

## remove nsIMsgDatabase.asyncOpenFolderDB() and .openMore()

Used only by tests, not main code.

## remove nsIAbDirectoryQueryResultListener (used only by C++)

obsoleted by nsIAbDirSearchListener?


## tidy up nsMsgDBFolder::GetPurgeThreshold()

should just return `int64_t`, in bytes. 
(currently returns threshold in KB).

## Replace PLDHashTable use with HashMap<> (or whatever).

Used in two places:
1) nsMsgDatabase (see Bug 1417018)
2) nsBayesianFilter

## GetOrCreateJunkFolder() is a bit insane.

- reimplement with GetExistingFolder(), not GetOrCreateFolder().


