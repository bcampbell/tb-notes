# Notes on MailStore conversion

When the user switches from mbox to maildir or vice versa, the
conversion is handled by:

    mailnews/base/util/mailstoreConverter.jsm
    mailnews/base/util/converterWorker.js

The conversion is very dependent on the type of the stores
and the type of folders - there are lots of checks and special
cases.

The converter iterates through the filesystem directly to
discover the messages. Shouldn't it use nsIMsgFolder iteration
to get the messages instead? At least for the source.

Once the folders have been converted, Thunderbird is restarted
to pick up the new ones.

## Alternative 1

Converting mailstores shouldn't require any knowledge of the store or
folder types (or even directory structure, barring the top-level
location within the profile). Get the xpcomm objects doing the hard
work, with the converter just orchestrating.

Pseudocode:

    function convertMailStore( srcStore, destType ):
        tmpLocation = CreateTempDir()
        destStore = new MailStore(destType, tmpLocation)
        convertFolder( srcStore.rootFolder(), destStore.rootFolder())
        move( tmpLocation, srcStore.filesystemLocation)

    funcion convertFolder( srcFolder, destFolder):
        for msg in srcFolder.messages:
            destFolder.addMessage(msg)

        // copy .msf, .dat, etc...
        // likely needs to be more clever than this - folders should know what they need.
        for f in srcFolder.supportFiles:
            destFolder.copySupportFile(f)

        // recurse into subfolders
        // NOTE: for non-local folders, we don't want to create folders on server!
        // Not sure how to address this.
        for srcSubFolder in srcFolder.children:
            destSubFolder = destFolder.createSubFolder(srcSubFolder.name)
            convertFolder( srcSubFolder, destSubFolder)

Downsides: tricky on the writing side, and avoiding side-effects with imap
folders and the like.


## Alternative 2

Use the nsIMsgFolder interface to iterate over the source messages (and so
not have to worry what type of store it is), but have the converter build
up the destination folders itself, directly to the filesystem
(and restart Thunderbird to switch over).


