# Tasks for GlobalDB work

_BenC 2024-04-22_

This is a list of tasks which I think need to be done for the GlobalDB and follow-on work.

It's sorted in rough order of dependence, although this is fuzzy. Most can be worked on somewhat concurrently.

The "Research:" tasks might result in work to refactor things to ease GlobalDB work.

The "Future:" tasks are ones which follow on from the GlobalDB work. Some rely on GlobalDB work (e.g. API improvements), some enhance it (IMAP extensions).


## Convert IMAP to not use UID as msgKey

Not specific to globalDB work, but a prerequisite (we want the DB to assign message keys).

- [Bug 1806770](https://bugzilla.mozilla.org/show_bug.cgi?id=1806770) - IMAP shouldn't use UID as message key.
- Lots of little changes everywhere.
- Can't hide behind a switch.

## Convert NNTP to not use article number as msgKey

Another prerequisite.

- [Bug 1877871](https://bugzilla.mozilla.org/show_bug.cgi?id=1877871) - NNTP shouldn't use article number as message key.
- Same as IMAP work, but simpler.
- Builds upon the IMAP work.

## Research: Threading

The way message threads work is a little jumbled and ill-documented.

- Document the nsIMsgThread interface properly.
- Identify any cleanup work that could/should be done separately to ease GlobalDB work.

## Research: investigate nsMsgDatabase::CreateMsgHdr et al

Mork and nsMsgDatabase have some odd practices that make it trickier to switch to another DB.

- Mork uses detached rows to add new message headers, which
  is quite different from other DBs.
- Document how and where nsIMsgHdr objects are created.
- Document how nsIMsgHdr objects are cached (there are multiple
  layers of caching).
- Identify any cleanup work that could/should be done separately to ease GlobalDB work.

## Implement existing XPCOM folder DB and msgHdr interfaces upon a global DB.

This is the core task - the heart of the GlobalDB work.

- [Bug 1572000](https://bugzilla.mozilla.org/show_bug.cgi?id=1572000) - [meta] database backed global message index
- Implement nsMsgDatabase, nsMsgHdr, nsMsgThread et al.
- Rest of system should Just Work (tm).
- Hide behind a runtime switch, to allow easier collaboration and
  reduce bit rot.

## Migration process: mork -> GlobalDB

Provide a smooth and invisible upgrade path for existing users.

- Convert users profile from per-folder mork DBs into single GlobalDB.
- one-time operation.
- Working prototype in [Bug 1802828](https://bugzilla.mozilla.org/show_bug.cgi?id=1802828) - Experiment with a sqlite & C++ global message db / index.

## Support metadata added by Add-ons.

Make sure we provide a great story for add-on development.

- Design required.
- Want to support current and future add-on requirements.
- Don't want add-ons to have free-for-all database access.
- Should be able to easily uninstall data along with the add-on.
- Implement, and work with add-on developers to migrate.

## Future: IMAP support for messages appearing in multiple folders

GlobalDB will have first-class support for messages appearing in more than one folder (eg gmail labels), but needs to coordinate with IMAP (and EWS, JMAP et al).

- "`OBJECTID`" IMAP extension. Used by Yahoo and likely others.
  - Currently progressing through the IETF standards process.
  - https://datatracker.ietf.org/doc/html/rfc8474
  - https://senders.yahooinc.com/developer/documentation/#imap-features-mail-object-id
- "`X-GM-EXT-1`" IMAP extension, used by gmail.
  - Used only by Google.
  - https://developers.google.com/gmail/imap/imap-extensions
  - Some support already in codebase, combined with icky hackery. Needs investigation and further work.

## Future: New GlobalDB API design

Take advantage of new opportunities offered by GlobalDB to improve other parts of the codebase.

- Design and implement new API for GlobalDB.
- Should be more performant than current interfaces.
- Should be more robust (explicit atomic transactions).
- Should be way more pleasant than existing interfaces.
- Can start experimenting quite early (almost immediately).
- Kill nsIMsgDatabase, nsIMsgHdr, nsIMsgThread et al.
- Still at the throwing-ideas-about stage (Ben, Geoff).

## Future: Converge MailExtension API with new GlobalDB API

MailExtension API and implementation can likely be simplified after GlobalDB work.

- MailExtension API uses similar concepts to a new GlobalDB API
- e.g. MailExtension `MessageID` and `FolderID` could be from GlobalDB IDs.
- Query mechanisms could be very similar, e.g.
  https://webextension-api.thunderbird.net/en/stable/messages.html#query-queryinfo

## Future: Conversation view (threading over multiple folders)

The main feature driving all this stuff in the first place!

- Requires new GlobalDB API - old interfaces are constrained
  to single folder.
- Most back-end functionality should already be in place, so this
  should be a front-end task.

## Future: Absorb/replace Gloda functionality

GlobalDB has a lot of overlap with Gloda, so it'd be nice to continue onward and replace Gloda completely.

- Research required into Gloda interfaces and capabilities.
- Global DB gets us most of the way to replacing Gloda.
- I think the missing part is full-text indexing.
- Ignoring addressbook indexing here...

