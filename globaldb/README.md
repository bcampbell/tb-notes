# Notes for the GlobalDB project

Background notes:

- [`2022-11-16-initial_globaldb_notes.md`](2022-11-16-initial_globaldb_notes.md)
- [`2023-05-24-globaldb_prototype_notes.md`](2023-05-24-globaldb_prototype_notes.md)
- [`2024-04-18-mork_schema.md`](2024-04-18-mork_schema.md) - rough outline of current mork message schema (such as it is ;- )

Task list is in [2024-04-22-tasks.md](2024-04-22-tasks.md).


## Status (as of 2024-06-06):

- Basic proof-of-concept prototype up and running late 2023.
- Patchset for the prototype is in [`2024-04-18-globaldb.patches`](2024-04-18-globaldb.patches).
- Bitrot since, so can't be applied directly (and we wouldn't want to anyway!)

Current goal is to implement a globaldb-based version of the existing nsIDatabase et al, in parallel with the existing mork-based implementations.

We'll use a feature-flag (pref) to switch between the versions where feasible.

Feature-flag rationale:

- Development keeps up-to-date in main tree without worrying about bitrot.
- Easier for collaboration. A separate feature branch would need continual rebasing upon mainline to stay relevant, and that'd start getting frustrating to synchronise across multiple developers.
- Better access to testers (just change a pref to try out the globaldb work as it stands).

## Current tasks

BenC:

1. ["Convert IMAP to not use UID as msgKey"](2024-04-22-tasks.md#convert-imap-to-not-use-uid-as-msgkey)
2. [Convert NNTP to not use article number as msgKey](2024-04-22-tasks.md#convert-nntp-to-not-use-article-number-as-msgkey)


