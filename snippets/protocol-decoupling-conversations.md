2024-12-04

Ben Campbell (🇳🇿 UTC+12)
I think the protocol should just provide what it has to the folder (along with the EWS ID), and the folder decides what to do with it. This might be full stream of RFC?22 message data, just the headers/metadata, or even just notifications of stuff that's happened on the server ("the message with EwsId <foo> has been marked read").
IMAP and POP3 and likely RSS and NNTP (and associated folders) all have the concept of receiving only the message header block. That's just passed to the folder side, which parses those headers to create an nsIMsgDBHdr to add to the database). IMAP syncs the message list (populates the database) like this before any full messages are ever downloaded.
I realise EWS might already have the message metadata in a cooked form (EWS Message structure)... so it'd be a case of serialising it as RFC?22 headers or creating methods on the EwsFolder which explicitly take an EWS Message structure and build an nsIMsgDBHdr from it
In any case - I don't want to bog the review down further even, so I think it's fine as it is, but I'd like to eventually push toward decoupling a lot of things that are currently intertwined (not just in ews!)
In my ideal outcome, you should be able to create and set up an EwsClient (or any protocol client object) in isolation in a unit test, give it a mock folder and run unit tests on it. I hate that our unit tests currently require everything to be up and running - protocol, folders, accounts, database, store etc etc etc...

Ben Campbell (🇳🇿 UTC+12)
nsIMsgDBHdr is really annoying because it's always a database row. But with mork that row doesn't actually have to belong to a table.
So there are lots of places where it creates one, populates it, then adds it to the table.
We need to move away from this - which probably means a) having a non-database-attached intermediate data structure/interface to represent message data, or b) using the RFC?22 headers as that structure. The code implicitly assumes b) all over the place right now, and most of the time I think it's reasonable (usually we are dealing with RFC?22.
But I know you're keen on a) and I think that adding EWS adds weight to that argument. Especially if you ever find yourself having to jump through hoops to serialise already nicely-cooked EWS message metadata down into crufty RFC?22, where we know it's just going to be immediately reparsed anyway!

leftmostcat (UTC-8)
I'm definitely in favor of not using `nsIMsgDBHdr` for the long term. I'd like to better understand the range of fields users can make Thunderbird display without fetching the full message and what we need for filters.

Ben Campbell (🇳🇿 UTC+12)
You can use an IMAP folder entirely without fetching the full message (online-only folders). The only time it fetches the full message in that case is when you click on it to display it (or potentially for downloading attachments - I forget if IMAP has specific support for just fetching attachments or not. I suspect it's up to the client to fetch the raw rfc?22 message and extract the attachment data itself, at least in base IMAP without extensions).
POP3 has support for downloading the headers + <N> lines of message body (so you can download, say, the first 10 lines of text as a preview). I think there are some obscure prefs somewhere which let you download partial messages via pop (such messages have the nsMsgMessageFlags::PartialPartial flag set, to indicate the local copy is truncated. Yay.)
I'd suspect NNTP is pretty biased towards not downloading the full message, just the headers (all those traditional .binary usenet groups). Again, it'll just send over the header block to the folder.
So with the headers themselves, it's all-or-nothing. I don't know of any cases where only a selection of headers are available.
some protocols (IMAP) probably also support metadata about attachments... but the client side still needs to be able to derive that stuff from the full message for the servers that can't do that (and so you likely won't be able to tell there are attachments until the full message has been downloaded).
For filtering, I think most match criteria are in the headers, but there are special cases for content matching, which obviously requires the full message. Filtering is handled per-protocol right now as far as I know - POP3 has some (broken) on-the-fly filter matching stuff, not sure about IMAP et al. I really want to unify filtering!

