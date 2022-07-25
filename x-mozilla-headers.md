# `X-Mozilla-*` headers

Local folders add a few custom headers to messages when they are stored to disk.
These headers stash message flags and keywords in the message, mirroring the values in the message database.

I think the original idea was that the mbox was the 'definitive' source of truth, and that the message database was just a summary - a throwaway index to make accessing messages easy, one which could always be rebuilt from the mbox.
This is still mostly the case for local folders - a "Repair Folder" will rebuild the database by scanning the mbox (or maildir!).

To avoid having to repack messages on disk when the metadata changes, the headers are written with some blank space which can later be rewritten in place.
The functions which perform this in-place update are `nsMsgLocalStoreUtils::RewriteMsgFlags()` and `nsMsgLocalStoreUtils::ChangeKeywordsHelper()`.

If a header is missing or doesn't have enough space for a in-place edit, it is generally just left up to the next folder compaction to rewrite the header with the full value.

## `X-Mozilla-Status` & `X-Mozilla-Status2`

These hold the message flags (`Read`, `Replied`, `Marked` etc. See 
`comm/mailnews/base/public/nsMsgMessageFlags.idl` for the full list).

`X-Mozilla-Status` holds the lower 16bits worth of flags, as a 4 digit hex number: `X-Mozilla-Status: xxxx`.

`X-Mozilla-Status2` holds the upper 16bits flags only, with the lower 16 bits zeroed. It's a 8-digit number with lower 4 digits always zero: `X-Mozilla-Status2: xxxx0000`.

Yes, this seems a bit bonkers. It should just be a single header. Historical reasons, I guess.

The flags are defined by `nsMsgMessageFlags`, in `comm/mailnews/base/public/nsMsgMessageFlags.idl`.


## `X-Mozilla-Keys`

This holds a list of any keywords the message is tagged with, eg:
`X-Mozilla-Keys: $label1 $label2`
By default, the value is padded with spaces to reserved about 80 characters for further in-place edits.

