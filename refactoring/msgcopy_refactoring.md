message copy is really hard to follow.

listeners are ill-defined, quirky and inconsistant.
move-to-trash complicates everything.
undo seems solid, but needs investigation and understanding.


Notes from matrix:
```

Brendan Abolivier (:babolivier) [CEST/UTC+2]

I've been spending the past few days looking at the message copy code - and btw thanks for the notes you shared on this a while back. One of the question I'm trying to answer is whether there's anything in there we could reuse in EWS. I feel like a lot of the copy-related code in nsMsgLocalMailFolder could be factored out to avoid completely reimplementing in EwsFolder (e.g. nsMsgLocalMailFolder::CopyMessages and the various calls it makes), and I wanted to know any thoughts you'd have about this, or gotchas that could make this tricky/undesirable?

BenC:

This is something I'd like to really dig into in person in Dublin. It's currently an icky mess and I run up against problems caused by it all the time!
Realistically, I think EWS is just going to have to reimplement it itself. But I'm hoping that it can be done in a much cleaner way that we can then use as the basis for a shared system.
I'll write up some proper notes but I'll outline a few off-the-top-of-my-head thoughts here now:

    We're a local, native app, so we should be blazing fast. This means that message copies should happen immediately locally, then get rolled back later if the corresponding server operation fails.

    that kind of implies local messages can be in a "speculative" state. That is, known locally, but not yet confirmed by the server. IMAP currently does this kinda sorta, but it's not explicit, and it's really hard to tell what's going on. I'd like to nail down an explicit mechanism that can be used by any protocol. I'm pretty sure IMAP doesn't have a robust way to roll back such messages if the server op fails.

    "local copy" here really refers to the database entry for the message. But if there's a local copy of the whole message available, that should be copied too. And the mechanisms for that should be shared across protocols.

    There are special cases, where shortcuts are taken. For example, moving/copying a message between folders (IMAP mailboxes) in the same account.

    In some of those cases - if the server supports it - the copied message is really the same message. (ie like a symlink). Like the label folders in gmail.
    I'm pretty sure EWS supports this, IMAP has a couple of extensions which support this too, although we don't really use them yet. But we should.

    message copies/moves are wrapped up in transaction objects, to support undo/redo. However, the initial operation isn't part of the transaction object, so redo is usually separately implemented. We should make more use of the transaction objects.

    moves and copies usually go through the same code paths. This gets really convoluted in the current code. In the cases where you have to implement a move with a copy+delete, the copy+delete should be separate operations. The transaction objects have a facility to let you merge smaller operations into one. So the user just sees a "Move" transaction (with undo/redo support), but behind the scenes that move transaction contains descrete copy and delete transactions.

    Going back to point 4, the current default lowest-common-denominator path for copying messages between different servers is to stream rfc?22 messages between them. But I'm not sure this is really needed, except for where we're transferring full local messages...

    if you're copying a message, then by definition we've already got a database entry for it. And copying those should be really simple (even allowing for having to scrub out protocol-specific fields -UIDs etc). So the database copy side should be divorced from the follow-on bit where you copy a fully-downloaded message.

    (last one, I promise!) We support a whole bunch of "Offline" operations, like where you can copy messages into an IMAP folder even if you're offline. They are stored up and attempted once you go online. But it's really fragile and makes the code ultra complicated. I think we should ditch offline operations except in really obvious circumstances, and fail otherwise. (eg: copy from IMAP to local where you've already downloaded a full copy? fine. Copy from local to EWS while offline? Nope.)

OK... already down in the weeds and I've hardly scratched the surface! I'll try and write this up properly.
Doesn't really help you with EWS - I think the get-it-working-now path is just the brute force do-more-or-less-whatever-ugly-crap-IMAP-does-but-for-EWS path... but I'd really like to properly figure out how it should work, and come up with a way to refactor things to get there.

```


From googledoc on [EWS move/copy](https://docs.google.com/document/d/1k2Z4W-gTiRPTMiw-yABOSVeqvy2jPn-qz_jPkxJKckM):

## Ben’s brain dump (how Ben thinks message copies should work).

Some observations:

1. If we know about a message, it has an entry in the msgDB. And all copy/move operations operate on messages we already know about. By definition.
2. Exception is for newly-composed messages or for copying a file into a folder. But I think that should be a separate path anyway (it’s more akin to a message being delivered to a folder where the msgDB entry is created by parsing the msg headers - and that stuff should be well covered elsewhere).
3. Copying msgDB entries is a bit of a faff with the current system, but not too bad. It’ll be trivial with a globalDB.
4. Can’t quite do verbatim msgDB copies - there are a few things that need to be scrubbed out, such as any server-side ID that referred to the source message. Same goes for “storeToken” field, used by the msgStore for local copies of full messages. But there’s not much you’d have to scrub.
5. An entry in the msgDB just tells us a message exists. It’s not the full message. If we need the full message, we need to fetch it from either the local msgStore (using “storeToken”), or download it from the remote server (using the server-ID for that message, eg IMAP UID).
6. We’re a local, native app, so we should be blazingly fast. This means copies should be performed immediately, even if that means marking a message as “speculative”. If the server later comes back and says the copy has failed, then the “speculative” message should be removed. IMAP handles “speculative” messages in a somewhat implicit way (it uses Message-ID to sync up, and I’m not confident that copy errors coming back from the server are ever cleaned up). It should be made much more explicit and robust.
7. We support a whole bunch of "Offline" operations, like where you can copy messages into an IMAP folder even if you're offline. They are stored up and attempted once you go online. But it's really fragile and makes the code ultra complicated. I think we should ditch offline operations except in really obvious circumstances, and fail otherwise. (eg: copy from IMAP to local where you've already downloaded a full copy? fine. Copy from local to EWS while offline? Nope.)
8. The current code merges copy and move operations (most copy functions have a “isMove” flag). This complicates things a lot. I think moves should be separated out. A lot of the time there are shortcut paths for moving things (eg server-side IMAP moves, or moving messages in a local maildir msgStore).
9. We don’t make as much of the nsITransaction system as we should. Usually we perform the operation, then use nsITransactions to encapsulate the undo/redo ops. But the redo op is almost always exactly the same as the original operation. So I think the original operation should be encapsulated inside the transaction too. (nsITransaction has provision for that).
10. nsITransaction also handles grouping, so a move transaction could be composed of copy and delete transactions, but the user just sees them as a single operation. This would simplify a lot of things and be way more robust.
11. In some cases - if the server supports it - the copied message is really the same message. (ie like a symlink). Like the label folders in gmail. I'm pretty sure EWS supports this. IMAP has a couple of extensions which support this too, although we don't really use them yet. But we should.
Proper support for this requires globaldb.
But in those cases we shouldn’t create a new msgDB entry for the copy. It’s the same message, and we should just mark it as also being in the destination folder (with globaldb, messages can be in multiple folders). There are some issues here - I suspect some protocols maintain some per-folder flags for the message, so the message can be marked “read” in one folder and “unread” in another maybe? Not 100% sure. Either way, I suspect picking a “least surprises to the user” approach will see us right.

So, when you copy a message from Folder A to Folder B, this is what I think _should_  happen:

1. If A and B are on the same server, and the server supports messages being in multiple folders at once, then we just tell the msgDB that the message is now also in folder B. All done. Early-out. Exit.
2. In the msgDB, create a duplicate entry for the message, and scrub it of any server-side or local-store details. Add the dupe entry to folder B.
3. If there’s a local copy of the full message held by A, copy it to B (ie from local msgStore A to local msgStore B).
4. If folder B represents a mailbox on a remote server, then:
  1. Mark the msgDB entry for the dest message as “speculative” (i.e. not yet confirmed by server)
  2. If A is on the same server, issue a server COPY command to perform a server-side copy.
  3. Else, if we’ve got a local copy of the message, start uploading it to the server
  4. Failing that, start downloading the message from A’s server and uploading it to B’s server.
5. We’re all done for now. The user can go about their business…
6. At some point we’ll hear back from the server.
7. If the server part of the operation failed, then delete the speculative (dest) message in B.
8. If the server part of the operation succeeded, then clear the “speculative” flag on the dest message in B.

All done.
Seems complicated, but it’s a thousand times simpler than what we currently have :-)

I’d handle Moves and Deletes similarly - separate out the server operation from the local side, and use a “speculative” flag to mark any messages which haven’t been confirmed by the server…

Braindump addendum:
Brendan asked on matrix what should happen when copying messages between different servers. My response overlaps with the steps I wrote above, but has a different enough perspective that I’m pasting it here too (It’s a brain dump! It’s meant to be all jumbled and confused :- )

I think when you step through in your mind what needs to happen, the Right Way (tm) kind of just falls out:

1. we already have the message metadata in the database, so we should copy that entry immediately to the destination folder (locally), in the interests of being responsive and quick.
2. the new db entry should be marked "speculative", and linked to a server copy operation which we issue at the same time.
3. the server copy will definitely require streaming the complete message (as rfc?22) up to the dest server.
4. if we have a local copy of the message, then we can use that as the source.
5. if we don't have a local copy of the message, then we'll have to stream it from the source server.
6. if the server-side operations fail, we need to remove the "speculative" message (and probably inform the user that something has gone wrong).
7. If/when the server side operations succeeds, we mark the message as no longer speculative (and attach a server-side ID to it: IMAP UID, EWS guid, whatever)
8. this all needs to be undoable (and redoable). Which means wrapping it up in a transaction.

(The "speculative" state I talk about could mean adding another message flag, or it could be implicit: any message on a server-synced folder which does not have a server-side ID attached to it should be considered "speculative").

