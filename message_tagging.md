# Message tagging

Messages may be tagged (Important, Work etc...)

On the client side, we've got a global list of defined tags, which are `nsIMsgTag` objects, managed by `nsIMsgTagService`.

The list of tags is stored in preferences, in `mailnews.tags.*`.

## Tag management

Five tags are created by default:
```
key        tag (name)    colour
----------+-------------+--------
"$label1" | "Important" | Red
"$label2" | "Work"      | Yellow
"$label3" | "Personal"  | Green
"$label4" | "To Do"     | Blue
"$label5" | "Later"     | Purple
```
(see `nsMsgTagService::SetupLabelTags()`)

In the GUI, the user can add tags or edit existing ones.
The `key` is immutable, so if the human-readable `tag` field is changed, the key will be left as it was.
So if the user renames a tag in "Manage Tags", the actual tag assignments to messages are unchanged, both in the local database and on the server.

The server includes the `key` in the message metadata it sends to the client.

The client sends the `key` to the server when tagging or untagging messages.

If the user creates a new tag, `key` is derived from the human-readable name by lowercasing them and replacing characters special to IMAP with underscores.
e.g. `Important Stuff` becomes `important_stuff`.

The local database maintains tags on nsIMsgDBHdr objects in the `keywords` property, a space-separated list of `key` strings.

## IMAP

Only the `key` is used.
It's stored in the `FLAGS` data for a message.

The tag name (`.tag`) and colour are purely on the client side.

It doesn't look like unknown tags received from IMAP are added to the list in `nsMsgTagService`.
So any tags used on the server which aren't defined on the client are just not displayed.

## Local folders

An attempt is made to store assigned tags in the sneakily-added local `X-Mozilla-Keys` header.
There is not always enough room to do this. It tries to edit the local message data in-place, so the information may not appear until the next folder compaction.
Compaction re-writes the message data and so the opportunity to create any extra space required.

