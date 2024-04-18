# Conversation view/Global msgDB notes


## UniqueID for message records

Current plan is to use message URI as the unique ID.
Existing msgDB uses 32bit int (nsMsgKey), unique to each folder.
Global DB needs a key which is unique over all folders.

I'd argue for keeping an integer ID (maybe extended to 64bits).

1. Memory usage. A msg URI string (e.g. `mailbox://bob@example.com/INBOX#12345`) is 40-50 bytes, say.
As a UTF-16 string in javascript, this is likely doubled, so 80-100 bytes.
It's also variable size, which means dynamic allocation might come into play (which implies likely cpu cache trashing).
Not really toooo much of a big deal, even when dealing with lists of millions of messages, but there doesn't seem to be any downside to using a 32 (or 64) bit int which maps to simple fixed size values.
2. Integer keys are better match for existing code.
Current C++ uses ints, so seems simpler to keep it like that rather than converting all nsMsgKey usage to strings.
The only change is that the keys are unique across the global DB rather than per-folder, and the existing code would cope with that just fine.
3. One justification for using URI strings is so we can use them directly to fetch messages.
But this is problematic: it implies all unique IDs need to be regenerated if a folder (or any of it's parents) is renamed or moved, or if an account changes username or host address.
This would also require updating any IDs held elsewhere.

## Additional properties

Talking about storing other data in the global database.
There are some notes on this in Magnus' doc, but there were a couple of minor gaps I just wanted to fill in:

1. For conversation view, each message needs to have a small snippet of preview text.
Generating the preview means streaming the message, which could be expensive if you're viewing a conversation with 100s or 1000s of messages.
Probably the preview would be 
The listview widget planned for conversation view supports on-demand population, so even if you're viewing a huge conversation, you can do on-demand generation of the messages currently in view. Each message has a fixed height, so even if the snippet isn't immediately available, that won't affect layout.
If we cache the snippets in the msgDB, then I guess we'd initially generate them all during the initial migration (which is likely pretty slow anyway).
After that, seems silly not to just generate preview snippets as new messages are streamed into the system (eg as imap messages are downloaded for offline storage, or when messages are loaded into a local folder).
It occurs to me that from time to time we might want to update the snippet-generation algorithm (eg better truncation rules or html sanitisation/conversion).
So we should keep in mind that maybe we'd want to regenerate them some time.
Either all at once as a migration for a new version, or incrementally, so the new snippets gradually replace the old over time.
No wise insights here - just wanted to flag up possible future options.
2. Other message headers.
At the moment, we just parse out a small subset of message headers (subject, to, from, date, message-id etc etc).
Some addons would find it useful to access other headers we don't currently process
Looking at a couple of random emails from gmail, they seem to have 8-10KB of headers, most of which is useless crap.
I'd say don't bother trying to store all the headers - it's just cruft which nobody cares about.
Let add-ons stream in the beginning of the message to get additional headers if they need to.
Alternatively, add-ins could have a hook into the message-parsing process, to allow them to add extra data to the msgDB records... A lot of careful designing would be needed to keep things manageable (eg migration management for new versions).
3. Full text, for easier indexing.
I would argue that a full-text indexer should just work by streaming in the message and applying whatever parsing it needs (html stripping, stemming, tokenisation).
So I wouldn't bother adding full-text to the DB.

## Versioning

One of the huge pain points in the existing DB setup is that there's no versioning, or way to manage schema updates and data migration.
This is handled in the plan, but I just wanted to point out how important it is!
There's a whole bunch of oddities in the existing msghdr that I want to kill but can't without doing boil-the-whole-ocean kind of migrations.

## The Gmail Issue

This is the issue where a single message can appear in multiple folders.
This is handled in a hacky gmail-specific way in the current code, but I think it's important to think it through and work out a proper approach to it.

It's complicated by the fact that a lot of messages are essentially the same, give or take a few headers (eg drafts, BCC)...

It's also not clear if Message-ID is reliable enough for this. (gmail adds it's own X-GM-MSGID header, for example).

More design required. I've got a nagging thought that if we don't have this sussed out, we might end up painting ourselves into a future corner.


## Layer boundaries

*WARNING* gut-feeling section ahead!

As a general principle, my preference is that lower levels should be native code (C++) and upper layers should be JS.
I rather like the idea of enforcing a more seriously-defined barrier for some systems using WebIDL say, so you can use the C++ side from javascript, but not (easily) vice versa.
It would let the C++ side streamline a lot of things internally, and provide more ergonomic APIs on the JS side (eg promises with specific types).
M-C definitely seems to be heading in this direction.

At the moment, with low layers exposed via XPCOM, we incur a lot of performance hits:
- C++ can't inline anything, or make good use of the CPU cache. Everything goes via virtual functions.
- Marshalling data between C++ and javascript sides can be expensive.
- Debugging across the boundaries is an utter arse.

There's an argument to be had on where the boundary should lie. I'm open to the appeal of "everything should be JS!".
But I think at the moment we're stuck with a bunch of C++, and that the msgDB falls firmly into that area of lower-level plumbing, so all my instincts still scream out "C++".
My lapsed-game-developer instincts want to know that every byte in the msgDB data structures is being used wisely :-) If you know your data structures are small enough to fit in RAM, a lot of stuff becomes much simpler and orders of magnitude faster.

