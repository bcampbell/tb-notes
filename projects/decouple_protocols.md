Currently the protocols are tightly coupled with specific folder classes.
Sink interfaces mediate, but they are also very protocol specific.

- protocols shouldn't know about folders (beyond a syncing/sink/notification interface)
- folders can know about protocols
- protocols do need to implement protocol handlers (eg "imap://") for fetching messages and attachments. But that scheme doesn't have to be used for other opertations.

goal:

Be able to test protocols using raw URLs and without a folder (or at the least, a small mock-folder which implements just enough).



random thoughts:

Identify common sink/listener interfaces that could be used by multiple protocols pairs? (eg checking for new mail)...


