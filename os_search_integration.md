# Thunderbird OS search integration (Windows Search, OSX Spotlight)

## OS Background

Both Spotlight and Windows Search index on a per-file basis.
So there is a one-to-one mapping from files to searchable items.
(TODO: seems like Windows Search might allow indexing of non-file
 content, but unsure).

Both OSs already have filters registered to index common file types
(eg .txt, word docs, image metadata...).

## the mbox issue

The default mbox storage in Thunderbird holds all the messages belonging
to a folder in a single file. It is plain text and can easily be indexed,
but the OS search mechanism can't distinguish individual emails.

As a workaround, when OS search integration is turned on, thunderbird creates an
extra directory, with a `.mozmsgs` extension.
Thunderbird mirrors indexable data for each email there, one file per email.
On OSX, the `.mozmsgs` dir is out in `~/Library/Caches/Metadata/Thunderbird/...`,
not within the normal Profile directory tree.
On Windows, the `.mozmsgs` directory is placed in the same location as
the folder it's representing.
See [bug 856087 - mbox to maildir conversion does not work if "Allow Windows Search to search messages" is enabled, chokes on mozmsgs folders](https://bugzilla.mozilla.org/show_bug.cgi?id=856087).

For OSX spotlight, a `.mozeml` file is created under `.mozmsgs` for each email.
This file is a `CFPropertyList`, serialised to an XML file (ie a `plist` file).
There is also a Spotlight plugin which adds `.mozeml` indexing to Spotlight.
The importer is compiled as an OSX framework bundle, "thunderbird.mdimporter".
Spotlight uses it to parse `.mozeml` files, returning a dictionary of metadata
to add to the index.

For windows search, `.wdseml` files are created under `.mozmsgs`.
(TODO: what format is the `.wdseml` file?)

TODO: links here to code which generates .wdseml and .mozeml files


## OS searching, user experience

The user enters a query using the OS Spotlight/WDS interface.
The matching documents are displayed - the `.mozeml` or `.wdseml` files.
Since Thunderbird has registered these file extensions, the user can
just double-click one of them to see the associated mail in Thunderbird. The OS will invoke Thunderbird, passing in the clicked file as a commandline parameter.
Thunderbird sees that it's a `.mozeml`/`.wdseml`, looks up the email
it represents, and jumps to it.
(TODO: confirm that this is what happens!)
(TODO: look at the startup code, give link to source here)

## THOUGHTS

If `.mozeml` and `.wdseml` files both contain the whole message (which
they kind of need to, for full indexing), could they just be replaced by
a standard email format (rfc822)?
This would unify indexing for mbox `.mozeml`, mbox `.wdseml` _and_
maildir emails.
The maildir emails would probably need to have a specific file extension
to enable the Spotlight/Windows Search to handle them (`.eml` seems standard).
TODO: do WDS and Spotlight _have_ to have special file extensions for custom indexers?
(looks like it, but worth confirming)

There is probably also an argument for disabling OS search integration
when using mbox, and requiring maildir for OS search integration (rationale:
simplifiation. All the `.mozmsgs` support could be stripped out).

On Mac, mail.app uses the [`.emlx`](http://mike.laiosa.org/2009/03/01/emlx.html) file format.
`.emlx` is one-email-per-file, and is indexed by default by Spotlight (TODO: confirm this!).

TODO: can WDS and/or Spotlight already handle .eml files by default? (no big deal - we can write a filter for them if needed)
TODO: does it make sense to use `.emlx` on OSX instead of our custom `.mozeml` files?
TODO: can Spotlight index files in a maildir? (ie under the normal user profile?)
or can it only index stuff under `~/Library/Caches/...`?

Related:

[Bug 290057 - Thunderbird should integrate with the Spotlight Search](https://bugzilla.mozilla.org/show_bug.cgi?id=290057)

[Bug 430614 - (GSoC) Thunderbird integration into Windows Vista/Windows Search indexer](https://bugzilla.mozilla.org/show_bug.cgi?id=430614)

[Spotlight docs](https://developer.apple.com/documentation/corespotlight)

TODO: add link to windows search docs

