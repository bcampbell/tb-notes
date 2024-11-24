# Papercuts

Little jobs to tidy up code.


## Remove nsImapCacheStreamListener::mCache2

Kill residual `nsImapCacheStreamListener::mCache2` (no longer needed).
Member var + init params.


## Comment cruft in `nsIInputStreamListener` (m-c)

Refers to missing param `alistenerContext`

## Kill `Get`/`SetMsgIsInLocalCache()` in URL

Not needed.

## IMAP SendData() should take a nsCString, not char*.

About 60 uses, and all but 10 already convert _from_ nsCString.

## IMAP `GetServerCommandTag()` should return nsCString.

About 50 uses, and all but 3 immediately convert it to nsCString!
Also, could probably calculate string from the `uint32_t` on-the-fly , and kill `m_currentServerCommandTag` member var.




