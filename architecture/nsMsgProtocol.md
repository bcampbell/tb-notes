# nsMsgProtocol notes

```
class nsMsgProtocol : public nsIStreamListener,
                      public nsIChannel,
                      public nsITransportEventSink
```

Derived classes implement their own LoadUrl() fn, and
assorted protected internal helpers.



