- Unifed message delivery (to folders)
  - shared mechanism for protocols to send messages to folders (currently all are ad-hoc).
  - use streams instead of start/data/end functions?
  - support multiple messages at once? (prevent interleaving)
  - How to transfer UIDs etc?

- kill foldercache
  - not needed after globaldb

- Use nsITransaction properly
  - currently we apply the operation, then add a transaction to undo (and redo) it.
  - we should use the transaction to perform the operation in the first place (and avoid separate code for redo).
  - use nsITransaction to encapsulate move operations as separate copy & delete phases inside.
    - this would simplify a _lot_ of copy code.

- Kill offline operations, beyond the obvious ones.
  - eg, can copy an IMAP message to a local folder if (and only if) we have an offline copy of it.
  - copying from local to IMAP if offline should result in a "sorry, can't do that" dialog.
  - don't store up local operations for later replay on a server - just a world of pain!

- Sort out folder creation (no more getorcreatefolder)
  - https://bugzilla.mozilla.org/show_bug.cgi?id=1679333
  - kill folderlookupservice (https://bugzilla.mozilla.org/show_bug.cgi?id=1734254)

- Factor out common message copy/move/delete code
  - factor out local side (same for all folder types)
  - robust transaction system

- Unified (or at least aligned) interface for asking protocols to move/copy/delete messages

- "Speculative" message state
  - for messages which are still awaiting confirmation from server
  - eg copying a message can be done instantly locally, but server op could still fail.

- Unify offline message storage
  - imap/news uses .offlineMessageSize
  - local folders use .messageSize 

- Rewrite message header parsing
  - assume all headers can be slurped into RAM (use google max headers size)

- Finish decoupling msgStore from database

- Kill stateful URLs
  - reduce use of URLs for non-docshell uses


