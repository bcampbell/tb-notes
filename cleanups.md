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

# Other stuff

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


## nsMsgDBFolder::GetChildWithURI()

use nsIMsgFolder instead of RDFResource


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

## unify nsIMsgFolderListener and nsIFolderListener

nsIFolderListener was retained to avoid breaking extensions.

## ditch XPCOM for things which are implemented only in C++

benefit:
- simplification
- more idiomatic C++ (less QueryInterface and nsresult checking)
- better encapsulation (can better choose what to expose to JS)
- easier debugging (eg see member vars for base classes)
- more optimisation opportunity for compiler (inlining etc)

eg: The folder classes.
Expose to JS via a very specific, JS-centric interface.

What is firefox policy on this these days?

## nsIMsgPluggableStore shouldn't be responsible for creating folders?

Should focus on storage, not folders or DB.

## nsMsgAccountManager::SetSpecialFolders() only used by PostAccountWizard()

It looks SetSpecialFolders() is only ever used by LoadPostAccountWizard()
in mail/base/content/msgMail3PaneWindow.js.

    $ cd comm
    $ grep -ir SetSpecialFolders *

## factor out folder flag policy?

see:
mailnews/base/src/nsMsgAccountManager.cpp nsMsgAccountManager::SetSpecialFolders() 

## factor out folder naming policy

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

