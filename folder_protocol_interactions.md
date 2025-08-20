# Folder <-> protocol interactions

Some notes on existing interfacing between folder and protocol code,
with an eye to factoring out the interfaces to share more folder-side code.




## IMAP Sinks

nsImapMailFolder implements:

- nsIMsgImapMailFolder
- nsIImapMailFolderSink
- nsIImapMessageSink

nsImapIncomingServer implements:

- nsIImapIncomingServer
- nsIImapServerSink
- nsISubscribableServer

nsImapProtocol implements:

- nsIImapProtocol
- nsIImapProtocolSink



## getting messages from server into folder


### updating a folder

- `nsImapMailFolder::UpdateFolder()`
- `nsImapService::SelectFolder()`
- `nsImapService::GetImapConnectionAndLoadUrl()` "{...}/select>{delim}{folderName}"
- `nsImapIncomingServer::GetImapConnectionAndLoadUrl()`
- `nsImapProtocol::LoadImapUrl()`
- ...

### transferring to folder

nsIImapMailFolderSink.parseMsgHdrs()
nsIImapMailFolderSink.AbortHeaderParseStream()

Folder (and service) uses `imapUrl->SetStoreResultsOffline(true)` to download messages for offline?


nsImapMailFolder methods:

EndOfflineDownload() (concrete)

// nsIImapMessageSink:
ParseAdoptedMsgLine()
NormalEndMsgWriteStream()
AbortMsgWriteStream()

// nsIImapMailFolderSink:
parseMsgHdrs()
AbortHeaderParseStream()

headerFetchCompleted()



nsMsgDBFolder::StartNewOfflineMessage() - calls msgStore GetNewMsgOutputStream()
nsMsgDBFolder::EndNewOfflineMessage() - calls msgStore FinishNewMessage() or DiscardNewMessage().
.stream is held by `m_tempMessageStream`

