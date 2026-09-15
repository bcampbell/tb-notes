I'd _really_ like to get errors sent back up the chain to be reported at the `nsIMsgFolder` method level (rather than the IMAP protocol, say, popping up an error dialog directly. sigh).

So, you tell the folder to delete some messages, and if it fails it provides you with enough information to tell the user everything they need to know (i.e. what's gone wrong and if there's anything they can do try to fix it).
But to do that, we need to get some rich, structured info back up the chain, and I don't quite have a good sense of what that'd look like.
We do want server-specific stuff ("Error: This server doesn't work on Tuesday!"), and authentication stuff ("This certificate has expired!"), and networky stuff ("DNS lookup failed to find example.com") etc etc...
But how do we convey what we need in a protocol-neutral way, in a form that can be localized where possible, structured so that callers can handle different errors differently (eg offer a retry for some errors).


