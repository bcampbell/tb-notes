List of mork message fields.

Not exhaustive (taken from experimental mork -> sql migration patch in Bug 1802828)

```
string message-id
string references
uint64_t date
uint64_t dateReceived
string subject
string sender_name
string recipients
string ccList
string bccList
string replyTo
uint32_t flags
int32_t priority
uint64_t size
string storeToken
uint64_t offlineMsgSize
uint32_t numLines
string preview
string junkscoreorigin
string junkpercent
string senderName
string prevkeywords
string keywords
string label
int remoteContentPolicy
int glodaId
? glodal-dirty
string xGmMsgId
string xGmThrId
string xGmLabels
int pseudoHdr
int enigmail
int notAPhishMessage
nsMsgKey threadParent
nsMsgKey msgThreadID
int protoThreadFlags
```


