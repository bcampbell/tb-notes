Filters are bonkers.

Two aspects:

## Matching

- mostly self-contained
- over-complicated XPCOM interfaces.
- current implementations often match against detached nsIMsgHdrs.
- Three variations:
  - nsIMsgHdr only
  - full headers (required for "List-Id:", for example)
  - full message (if matching against message text)

-> ditch nsIMsgHdr filtering entirely? Just pass full headers... maybe. Maybe not.


## Actions

Complications due to filtering _before_ message added to DB - requires icky custom copy/move code.

Exchange bypasses this by applying filters after adding messages to DB.
Can we do this for IMAP and POP3 also?


## Thoughts

- Serverside filters, usually using sieve
- Users want both client and server filters, but not muddled up (keep them clear)
- use sieve subset as our serialzation format?
  - can then use client-side GUI filter editor to edit both client filters and server-side filters (assuming the sieve isn't tooooo complex).
- IMAP has extensions for accessing sieve file
- just make a sieve engine for the client?
  - probably needs custom extensions, as sieve doesn't have conditions or actions for tags/keywords etc...
