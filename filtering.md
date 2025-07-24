# Notes on filtering




## Filters

- Filter list is held by the nsIMsgIncomingServer

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


## Scope and Adaptors

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

## Spam classification

https://support.mozilla.org/en-US/kb/thunderbird-and-junk-spam-messages

- Spam filter is the only plugin?
- What about extensions?
- nsBayesianFilter is created by nsMsgIncomingServer::GetSpamFilterPlugin()
  (singleton?)

- GetSpamFilterPlugin() is used by:
  - nsMsgDBFolder::CallFilterPlugins()
    - the main thing.
  - nsMsgDBView junk/unjunk commands
  - nsImapMailFolder::GetShouldDownloadAllHeaders()
    to determine if we need all the rfc822 headers, not just a subset.

Conclusion: nsMsgDBFolder::CallFilterPlugins() is the place which does spam classification.

### nsBayesianFilter

- the only implementation of nsIJunkMailPlugin (and nsIMsgFilterPlugin). 
- also implements nsIMsgCorpus
  - corpus stored in `training.dat` and `traits.dat`.



### nsMsgDBFolder::CallFilterPlugins()

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

IDEA:
Maybe nsIJunkMailClassificationListener should have an onDone() callback too.
(or even onStart() as well for completeness)
 
### Classes


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

## Filters in IMAP

- Incoming filters are run on Inbox and folders with applyFilters set.
- Spam filter is set up as a temporary filter?
- There is server-side spam filter support. How does this work? Is it used?

`nsMsgDBFolder::CallFilterPlugins()` called by:
  -`nsImapMailFolder::HeaderFetchCompleted()` if filter list doesn't require message body.
  -`nsImapMailFolder::NormalEndMsgWriteStream()` if filter list does require body.
     - called after invoking `filterList->ApplyFiltersTohdr()`

`filterList->ApplyFiltersToHdr()` called by:
  - `nsImapMailFolder::NormalEndHeaderParseStream()` if filter list doesn't require body.
     - called from `ParseMsgHdrs()` (`nsIImapMailFolderSink` member)
  - `nsImapMailFolder::NormalEndMsgWriteStream()` if filter list does require body.


## ProcessingFlags

Folders maintain sets of messages that require some kind of processing.
There are flags, but best to think of it as a set of messages for each one.

The sets are defined as nsMsgProcessingFlags, in `nsMsgMessageFlags.idl`:

`ClassifyJunk` - needs junk classification
`ClassifyTraits` - needs traits classification
`TraitsDone` - completed any needed traits classification
`FiltersDone` - completed any needed postPlugin filtering
`FilterToMove` - has a move scheduled by filters
`NotReportedClassified` - new to folder and has yet to be reported via the msgsClassified notification.

Separately the folder also maintains a set of new messages.
But there were issues with messages being classified twice, hence the later addition of `NotReportedClassified`.

