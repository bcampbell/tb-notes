I've got some further thoughts on folder compaction and locking (more bigger-picture stuff rather than directly applicable here, so this is more to lay it out in my own mind than anything specific to this bug:- ) :

1. during compaction, the old mbox should be locked for writing, but there's no reason it can't be read from
2. there's no reason the database needs to be locked during compaction (assuming mbox writes are prevented, which also prevents altering .storeToken etc)
3. when the compaction finishes, the new mbox should be atomically installed, and all the storeTokens/messageSizes in the DB should be atomically updated.

We can't really do 3 yet, although just batching up all the new storetoken and size values and applying them to the database in one go probably gets us most of the way there (actually mork does have a simple transaction system for rolling back, it's just that our interfaces stop us accessing it. sigh).

But the point being that the database changes probably shouldn't be done to a separate database, as long as  we can (reasonably) roll them back if the mbox replacement fails.

And during compaction, as long as we prevent any writes to the old mbox, there's no reason the mbox or DB need to be locked for reads (so everything else should just be able to carry on as usual and not care that there's a compaction happening, just not writes)

Anyway, for now, the folder "lock" is the granularity we've got, but ultimately we'd want some finer control over locking (the compaction should really just be entirely hidden inside the mbox system, but for the DB update. No other parts of the code should ever need to know about compaction).

