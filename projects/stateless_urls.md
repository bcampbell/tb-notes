# Stateless URLs (WORK IN PROGRESS!)

## The issue

Our urls are stateful, more akin to request objects than the nsIURI objects in M-C.
They hold all kinds of information about the request, and how to handle it.
This has some bad implications:

- Can't pass URLs across threads.
- Request state is split out across multiple places (url, channel, etc).
- Leads to arcane procedures for issuing and handling requests.
- General oddness: e.g. nsImapProtocol acts as a connection _and_ an nsiIChannel.
- Lots of code relies on URLs being QIed to specific type, rather than just being a URL.
- URLs holding an identical address (spec) are not equivalent.

### Case Study: nsImapService.SelectFolder()

```
Call nsImapService.SelectFolder(folder, urlListener, msgWindow).
  - Creates an imap URL object
  - url->SetMsgWindow(msgWindow)
  - url->SetUpdatingFolder(folder)

  - Call nsImapService::SetImapUrlSink():
     - url->SetImapMailServerSink(folder.server)
     - url->SetImapMailFolderSink(folder)
     - url->SetImapMessageSink(folder)
     - url->SetFolder(folder)

  - rv = GetImapConnectionAndLoadUrl(imapUrl, nullptr, aURL);
     - protocol = nsImapIncomingServer::GetImapConnection()
     - protocol->LoadImapUrl(url)
```

## Goal

Use the nsIChannel/nsIRequest model as M-C uses it.

nsIChannel usage:

```
/**
 * The nsIChannel interface allows clients to construct "GET" requests for
 * specific protocols, and manage them in a uniform way.  Once a channel is
 * created (via nsIIOService::newChannel), parameters for that request may
 * be set by using the channel attributes, or by QI'ing to a subclass of
 * nsIChannel for protocol-specific parameters.  Then, the URI can be fetched
 * by calling nsIChannel::open or nsIChannel::asyncOpen.
 *
 * After a request has been completed, the channel is still valid for accessing
 * protocol-specific results.  For example, QI'ing to nsIHttpChannel allows
 * response headers to be retrieved for the corresponding http transaction.
 *
 * This interface must be used only from the XPCOM main thread.
 */
```

A main goal should be to allow anyone to easily:
- Craft a URL to perform some TB protocol operation (eg delete a message)
- Call newChannel() to create the request object.
- Start the request
- Handle start, stop and data-available callbacks (even if a lot of operations - such as deleting messages - won't need to output data).

- Replace channel-related use of `nsIUrlListener` with `nsIRequestObserver`.

- Have documentation for all our internal protocols (i.e. how to construct URLs for imap://, mbox:// et al).

## Steps

Tricky to know where to start. I suspect some throwaway exploratory coding might be in order.

Some random thoughts:

- Documenting the existing URL schemes in detail would help.
- Most of the C++ URL classes inherit nsMsgMailNewsUrl, so trying to strip that back to the bone might be a good starting point.
- Converting nsMailboxService might be a good place to start - it's reasonably self-contained.
- Or maybe the JS POP3 implementation - it'd be quicker to poke about in JS.

For IMAP, there are a few architectural things I'd probably change:

- `nsImapProtocol` should be `nsImapConnection` (and not be an nsIChannel!).
- Create a new `nsIChannel`-derived `nsImapRequest` object to handle all the per-request state.

There's a lot more fleshing out needed here.

## Relevant bugs

Bug 1729228 - [meta] C-C URL classes should just hold URLs (nsIMsgMailNewsUrl et al)

