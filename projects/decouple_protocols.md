Currently the protocols are tightly coupled with specific folder classes.
Sink interfaces mediate, but they are also very protocol specific.

goal:

Be able to test protocols using raw URLs and without a folder (or at the least, a small mock-folder which implements just enough).


random thoughts:

Identify common sink/listener interfaces that could be used by multiple protocols pairs? (eg checking for new mail)...


