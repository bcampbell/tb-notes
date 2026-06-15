# GlobalDB overview

2026-06-15 BenC

The general idea is to replace the existing per-folder legacy mork database system with a global database.

This lets us do conversation views, improve performance, robustness and error handling.

Ultimately it lets us massively simplify a lot of the code.


## Search

- there'll be the ability to construct general-purpose search filters, eg:
	+ "All the messages in this folder"
	+ "All messages in this conversation thread"
	+ "All messages marked 'read' and with the word 'grapefruit' in the subject but exluding all messages older than 5 days from anyone called 'bob'",
	+ etc...
- Includes fulltext (i.e. replace gloda too)
	+ NOTE: can't index message until it's been fully downloaded (and not all messages meet criteria for downloading). Some thought required.


### Multilingual fulltext indexing

QUESTION:

How should fulltext indexing handle multiple languages?
- Stemming rules vary wildly.
- Is there a good way to guesstimate the language(s) of a message?
- Messages containing a mix of languages
	+ e.g. a lot of official emails in Wales are bilingual

## LiveView

New mechanism to replace all the current ad-hoc views and bodges.

- things can register any search criteria (as above).
	- e.g. "Tell me if anything in this folder changes"
- notifications received when anything in the search results changes - additions, removals or modifications.
- can be used for normal per-folder views, custom views, virtual folders...

QUESTION:

Can liveviews be used to replace _all_ database/folder notification (current listener/notificaiton system is very ad-hoc and hard to trace).


## Atomic operations

The global DB should support robust atomic operations (unlike the old system).

QUESTION:

Should DB have explicit transaction support? (i.e. explicit begin, low-level operations, commit/rollback)

Or should it provide app-centric methods which are atomic?

BenC: 
> Latter gives implementation much more flexibility and is probably simpler. It seems like the way to go to me.
>
> But might not be expressive enough for complex operations?
> Should work through some examples.


## Data model changes

- Support messages being in more than one folder (i.e. mirror data model used for gmail, JMAP, IMAP Object Identifiers etc)
	+ messages can't be shared across servers
	+ only for servers which support the model
	+ provides message move/copy shortcuts


## General

- All messages in one database
- `nsMsgKey` will be unique across whole system (not just per-folder)
- Want to minimise xpcom-boundary crossings. Performance should be paramount.
- Async where possible.
- More ergonomic APIs. (eg liveview serves JS-land view all the data it needs up front to, say, display a list of messages)
- Hide caching in DB layer.
- deCOMtaminate where sensible.

## Migration from current system

Implement legacy interfaces on top of new global DB so app continues to work - `nsIMsgDBHdr`, `nsIMsgDatabase` et al.

## Moving beyond current system

- Kill `nsIMsgDBHdr` et al.
- Use unique `nsMsgKey` to refer to messages
- Manipulate messages using database API, rather than by `nsIMsgDBHdr` methods.
- massively simplify existing XPCOM-heavy code


## Add-ons

TODO: add notes that John wrote up in Toronto

