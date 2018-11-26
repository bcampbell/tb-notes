


# nsIMsgFolder::incomingServerType could be ditched?

If every folder has a server (which does seem to be the case with
folder-lookup-service), incomingServerType uses should be replaced by:

    folder->GetServer()->GetType();

or something.

Not many usages:

    $ grep -ri incomingServerType comm


# unify OnMessageClassified() handlers

nsImapMailFolder::OnMessageClassified() and
nsMsgLocalMailFolder::OnMessageClassified() seem to do the same thing, but
the imap one uses a move coalleser to perform the move async.
Should convert the local folder to also be async, and use the same code.

# nsMsgIncomingServer::GetMsgFolderFromURI() is bonkers

first param, folderResource, is redundant.


# nsMsgDBFolder::GetChildWithURI()

use nsIMsgFolder instead of RDFResource


# CreateStorageIfMissing() is misleading name

nsMsgLocalMailFolder::CreateStorageIfMissing() at least seems
entirely concerned with linking up dangling folders...

# CreateStorageIfMissing() - delete altogether?

used by only 2 fns in C++:

- GetOrCreateJunkFolder()
- nsMsgCopy::CreateIfMissing()

and in javascript:

- comm/mail/base/content/mailCommands.js
- comm/mail/base/content/mailWindowOverlay.js
- comm/mailnews/imap/test/unit/test_saveTemplate.js
- comm/mail/test/mozmill/folder-pane/test-folder-pane.js


# special case handling for junk folder localized name

The default junk folder is supposed to be called "Junk" on disk, but
appear in the UI with a (potentially) localized name.
There's a little special-case handling in msgUtils.cpp 
GetOrCreateJunkFolder(), resulting from Bug 270261
    https://bugzilla.mozilla.org/show_bug.cgi?id=270261

It seems like this issue extends to other folder types?
Shouldn't there be a generalised mechanism to handle it?


# nsMsgDBFolder::VerifyOfflineMessage() not used?

Doesn't ever seem to be referenced.
Looks for "From -" line, which is dodgy...

  $ grep -ir VerifyOfflineMessage comm

