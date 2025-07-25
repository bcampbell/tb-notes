Currently all the protocols handle their own unit tests separately.
This kind of mirrors how the protocols currently all have their own implementations with very little sharing.

It'd be nice to have a solid set of tests that cover all the main operations, which can be run against all the protocols.

All the standard stuff:
- folder naming/renaming
- moving/copying messages
- moving/copying folders
- deleting and move-to-trash
- checking for new messages
- filters
- junk mail classification
- checking that folder stats were correct (eg total message count, number of new messages etc)
- etc etc etc

Going further, we could have tests which work with *combinations* of protocols.
e.g. a message-copy test which runs against all possible pairs of protocols (allowing for protocol restrictions - eg news is read-only, but could still be a source protocol).

One approach to this:
- do a survey of all the existing per-protocol tests and collate a list of what we want to cover.
- pick one category of tests at a time (eg filters) to tackle.
- adapt existing tests where reasonable, else write protocol-neutral replacements.
- delete obsolete tests, leaving ones which genuinely test protocol-specific features.




