


```
[13:52] <bcampbell> Does anyone know when runnables scheduled by NS_DispatchToMainThread() get run? I'm assuming the main thread probably executes them as part of a general main loop (ie handle window events, call any pending runables etc) but the docs don't seem to cover any details
[13:53] <bcampbell> (and yes, I realise that this is really a firefox question, but I figured I'd ask here first :- )
[13:54] <darktrojan> that's how I understand it
[13:54] <darktrojan> I could be wrong though
[14:01] <bcampbell> darktrojan: thanks! I'm assuming all our javascript and GUI runs on the main thread, right (except for explicit workers)
[14:02] <darktrojan> yes
[14:05] <bcampbell> I figured so, but doesn't pay to assume such things ;-) Thanks
[14:07] <darktrojan> I hate to think how much more of a mess the code would be otherwise
[14:09] <bcampbell> yeah, it'd be kind of like discovering the laws of thermodynamics work differently on Thursdays...
[14:11] <jcranmer> bcampbell: the only thing that runs off-main-thread in TB is IMAP
[14:12] <jcranmer> (I guess technically the necko socket pump is off-main-thread, but it proxies everything back to main thread anyways)
[14:13] <jcranmer> so the way xpcom handles threads is that each thread has an event loop that pumps events
[14:13] <jcranmer> NS_DispatchToMainThread dumps the event at the end of the main thread
[14:13] <jcranmer> main thread's queue*
[14:13] <jcranmer> except that sometimes it promotes the event to the head of the queue to prevent deadlock
[14:22] <jcranmer> bcampbell: https://dxr.mozilla.org/mozilla-central/source/widget/nsBaseAppShell.cpp#151 is essentially the event loop of the main thread
[14:28] <jcranmer> hmm, looks like event queues got more complicated since the last time I looked

```
