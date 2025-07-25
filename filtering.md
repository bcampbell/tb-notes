# Notes on filtering

## Filters

Each nsIMsgIncomingServer has a filter list (`nsIMsgFilterList`), which has a list of filter objects (`nsIMsgFilter`).
A filter is a set of search terms (`nsIMsgSearchTerm`), along with a number of actions (`nsIMsgRuleAction`) to apply to macthing messages.

There is a per-server `msgFilterRules.dat` text file which holds the filter list. This file is loaded lazily by `nsMsgIncomingServer::GetFilterList()`.

Some filter search terms match against the `nsIMsgHdr` objects, so do not require the whole message (so can be used on non-offline messages).
Other terms require the full, raw RFC822 message.

Junk classification is handled by a separate mechanism, the `nsIJunkMailPlugin`.
It looks like this was originally designed to allow arbitrary extra filter plugins, but it's not clear this feature is ever used (or even works).


### Filter requirements

The filter criteria are defined as search terms.
Some search terms just need the `nsIMsgDBHdr` (ie message entry in the database).
Some search terms need the whole body of the message (if you're matching the message text).

The filter system also has provision for passing in the full header block of the RFC822 message.
Presumably this is to allow matching against headers which we _don't_ parse for storing in the database (i.e. data not stored in the `nsIMsgHdr`).

This complicates things.
For IMAP, you'll often just download the headers of the message (the full message may or may not be downloaded later for offline use).
But if there are filters which require the body, then they must be deferred until the whole message is available.

The per-protocol folder code which handles this stuff gets pretty twisty-turny.

### "High level" invocation

The higher-level methods for running filters are `nsIMsgFilterService.applyFilters()`/`nsIMsgFilterService.applyFiltersToFolders()`.
These run filters on folders (TODO - on all messages in the folder???) and perform the required actions upon matching messages.
They are async functions, invoking an `nsIMsgOperationListener` when done.
Actions such as copying or moving messages are delegated to the nsMsgCopyService.

Junk classification is _not_ performed.

This higher-level interface used when filters are manually run - e.g. by the "Run Now" option in the filter editor GUI.

TODO: how does this high-level interface deal with non-offline messages with body-matching terms?


### "Low level" invocation

The protocol-specific folder classes don't use the high-level filter methods for incoming messages.
Instead, they invoke `nsIMsgFilterList.applyFiltersToHdr()` upon each new message in turn as it arrives.

The filtering might be done upon receipt of just the message headers, or it might be deferred until the whole message has been downloaded (depends on the search terms).

The incoming-message filtering is applied _before_ the message is added to the database.
It relies on a quirk of mork, which allows for detached database rows.
The headers for the new message are parsed and a nsIMsgHdr object is built up, but not yet attached to the message table in the database.
The data is stored as a row in the database, but not part of any table.
That detached nsIMsgHdr is then passed into `applyFiltersToHdr()`.
If a match is made, the actions are handled by the protocol-specific code.
Because the message is not yet in the database, the standard message copy/move code cannot be used, and each protocol has it's own (shonky) implementation...

In the protocol-specific folder code, the filtering is often combined with junk classification.
Filters can run either before or after the Junk classification.
If filters are run after the junk classification, the higher-level (`nsIMsgFilterService`) functions can be used - by which time the message has been properly added to the folder's database, so no shonky per-protocol copy/move hacks are required.

### Spam classification

Background from a user PoV: https://support.mozilla.org/en-US/kb/thunderbird-and-junk-spam-messages

- nsMsgDBFolder::CallFilterPlugins() is the place which does spam classification.
- `nsIJunkMailPlugin` is a `nsIMsgFilterPlugin` (the only plugin?)
- implemented by `nsBayesianFilter`.
- What about addons? (TODO: check, but I don't think there's any way to hook in extra filter plugins)

When `CallFilterPlugins()` is finished, it'll automatically run `nsIMsgFilterService.applyFilters()` if needed, for any post-junk-classification filters.

Loose ends (TODO):
- server-side filtering?
- handling for trusting server-side spam classification (spamassassin et al) - where?
- There's also Trait classification. Is Spam classification built on top?

### nsBayesianFilter

- nsBayesianFilter is created by nsMsgIncomingServer::GetSpamFilterPlugin()
  (singleton?)
- the only implementation of nsIJunkMailPlugin (and nsIMsgFilterPlugin). 
- also implements nsIMsgCorpus
  - corpus stored in `training.dat` and `traits.dat`?
- nsMsgDBView junk/unjunk commands call methods on this to update (retrain) the corpus.

### Filters in IMAP

- Incoming filters are run on Inbox and folders with "applyFilters" set.
- There is server-side spam filter support. How does this work? Is it used?

`nsMsgDBFolder::CallFilterPlugins()` called by:
  - `nsImapMailFolder::HeaderFetchCompleted()` if filter list doesn't require message body.
  - `nsImapMailFolder::NormalEndMsgWriteStream()` if filter list does require body.
     - called after invoking `filterList->ApplyFiltersTohdr()`

`filterList->ApplyFiltersToHdr()` called by:
  - `nsImapMailFolder::NormalEndHeaderParseStream()` if filter list doesn't require body.
     - called from `ParseMsgHdrs()` (`nsIImapMailFolderSink` member)
  - `nsImapMailFolder::NormalEndMsgWriteStream()` if filter list does require body.

### Filters in local/pop3

TODO
mostly similar outline to IMAP, but spread out between message parser, pop3sink and folder code.


### nsMsgDBFolder::CallFilterPlugins() details

These member variables are set up in `CallFilterPlugins()`, then used by `OnMessageClassified()`callback:

- `mBayesJunkClassifying`
- `mBayesTraitClassifying`
- `mPostBayesMessagesToFilter` - list of messages to run PostPlugin filters (once classification complete).

Other relevant member vars:

- `mClassifiedMsgKeys`
   - tracks classified messages over multiple OnMessageClassified() calls.
   - THIS IS NEVER CLEARED!? Should be cleared before callin classifyTraitsInMessage() maybe?
- `m_saveNewMsgs` - retains messages lost by ClearNewMessages()

Steps:

- Bails out if folder is locked
- Decides if folder should have spam filter run on it (not on rss or newsgroup, not Junk/Trash, etc...)
- Decides if trait processing is needed
  - checks the trait service, to see if proindices other than `nsIJunkMailPlugin.JUNK_TRAIT` are enabled.
- check the filter list for `nsMsgFilterType::PostPlugin` filters.
- get the list of new messages to consider
  - database holds an in-memory list of "new" messages (definition of "new" a little fuzzy)
  - but UI can clear the db new list, so folder maintains `m_saveNewMsgs` too...
- does a lot of fiddling with processingflags to mark messages for processing...
- calls nsIJunkMailPlugin.classifyTraitsInMessage()
   - invokes callbacks.
   - definitely nsIJunkMailClassificationListener.onMessageClassified()
   - maybe also nsIMsgTraitClassificationListener.onMessageTraitsClassified()???

IMAP and Localfolder have custom OnMessageClassified() callbacks which handle moving spam messages into the junk folder, but they both also call the base nsMsgDBFolder::OnMessageClassified() implementation too.

OnMessageClassified() is invoked with a null message to signify the end of the processing batch.
A little clunky, but could easily be broken out into a separate `onDone()` callback (and probably an `onStart()` for completeness.

 
## Class diagrams

### Filters, filterLists, actions

```{mermaid}
classDiagram

  class nsIMsgFilterService {
    <<Interface>>
    applyFiltersToFolders(filterList, folders, ...)
    applyFilters(filterType, hdrs, ...)
  }

  class nsIMsgFilterList {
    <<Interface>>
    void applyFiltersToHdr(filterType, msgHdr, hitNotify, ...)
  }

  class nsIMsgFilter {
    <<Interface>>
    bool MatchHdr(hdr, ...)
    filterType : nsMsgFilterType
  }

  nsIMsgFilter --> "*" nsIMsgSearchTerm : searchTerms
  nsIMsgFilter --> "1" nsIMsgFilterList : filterList
  nsIMsgFilter "1" --> "*" nsIMsgRuleAction : actionList


  class nsIMsgFilterHitNotify {
    <<Interface>>
    bool applyFilterHit(filter)
  }

  class nsIMsgRuleAction {
    <<Interface>>
    type : nsMsgFilterAction
  }

  nsIMsgFilter <|-- nsMsgFilter
  nsIMsgFilterList <|-- nsMsgFilterList
  nsIMsgFilterService <|-- nsMsgFilterService
  nsIMsgRuleAction <|-- nsMsgRuleAction
  nsIMsgSearchTerm <|-- nsMsgSearchTerm
```


### Scope and Adaptors

Not sure if used by filters...

```
classDiagram
  class nsIMsgSearchAdapter {
    <<Interface>>
    bool search()
    validateTerms()
    currentUrlDone(rv)
    addHit(msgKey)
    addResultElement(msgHdr)
    encoding: string
    searchCharset : AString
  }

  nsIMsgSearchAdapter <|-- nsMsgSearchAdapter
  nsMsgSearchAdapter <|-- nsMsgSearchOfflineMail
  nsMsgSearchAdapter <|-- nsMsgSearchNews
  nsMsgSearchAdapter <|-- nsMsgSearchOnlineMail
```


???

```
  class nsIMsgSearchScopeTerm {
    <<Interface>>
    getInputStream(hdr)
    closeInputStream()
    folder : nsIMsgFolder
    searchSession : nsIMsgSearchSession
  }
```

### Filter plugins

- nsIJunkMailPlugin is only known plugin.

```{mermaid}
classDiagram

  class nsIMsgFilterPlugin {
    <<Interface>>
    bool shouldDownloadAllHeaders
    shutdown()
  }

  class nsIJunkMailPlugin {
    <<Interface>>
    bool userHasClassified
    classifyMessage(uri, window, listener)
    classifyMessages(uris, window, listener)
    classifyTraitsInMessage(...)
    classifyTraitsInMessages(...)
    setMessageClassification(...)
    setMsgTraitClassification(...)
    resetTrainingData()
    detailMessage(...)
  }

  nsIMsgFilterPlugin <|-- nsIJunkMailPlugin

  class nsIMsgTraitDetailListener {
    <<Interface>>
    void onMessageTraitDetails(...)
  }

  class nsIMsgTraitClassificationListener {
    <<Interface>>
    onMessageTraitsClassified(uri, traits, percents)
  }

  class nsIJunkMailClassificationListener {
    <<Interface>>
    onMessageClassified(uri, classification, junkPercent)
  }

  class nsIMsgCorpus {
    <<Interface>>
  }

  nsIJunkMailPlugin <|-- nsBayesianFilter
  nsIMsgCorpus <|-- nsBayesianFilter

```

## ProcessingFlags

nsMsgDBFolder implementation maintains sets of messages that require some kind of processing.
It's an accounting system to track the state of incoming messages, but it seems to be a little fragile and ill-defined.

There are flags, but best to think of it as a sets of messages: "these messages need classification", "these need filtering" etc etc).

The sets are defined as nsMsgProcessingFlags, in `nsMsgMessageFlags.idl`:

- `ClassifyJunk` - needs junk classification
  - set by `nsMsgDBFolder::CallFilterPlugins()` on all new messages which are slated for spam classification.
  - cleared in `nsMsgDBFolder::OnMessageClassified()`
  - seems a bit redundant...
- `ClassifyTraits` - needs traits classification
- `TraitsDone` - completed any needed traits classification
- `FiltersDone` - completed any needed postPlugin filtering
  - used _only_ in `nsMsgDBFolder::CallFilterPlugins()`.
  - set when message is queued for post-bayes filtering, but *never* cleared.
- `FilterToMove` - has a move scheduled by filters
  - set when message queued to be deleted or moved to another folder by filter action.
  - used in IMAP & local folders (`OnMessageClassified()` handler) to prevent moving messages to spam folder when already queued for moving by a filter.
- `NotReportedClassified` - new to folder and has yet to be reported via the msgsClassified notification.
  - nsImapMailFolder::NormalEndHeaderParseStream() sets this on all newly-downloaded messages (unless they've been moved by a filter before classification).

Separately the folder also maintains a set of new messages.
But there were issues with messages being classified twice, hence the later addition of `NotReportedClassified`.



