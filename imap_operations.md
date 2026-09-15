# IMAP operations.

This is an attempt to document action values in the imapURL, the IMAP commands they map to, and the methods called on the Sink classes.

From `nsIImapUrl.idl`:
```
  // nsImapAuthenticatedStateUrl urls
  // since the following url actions require us to be in the authenticated
  // state, the high bit is left blank....
  const long nsImapTest  = 0x00000001;
  const long nsImapCreateFolder  = 0x00000005;
  const long nsImapDeleteFolder  = 0x00000006;
  const long nsImapRenameFolder  = 0x00000007;
  const long nsImapMoveFolderHierarchy = 0x00000008;
  const long nsImapLsubFolders  = 0x00000009;
  const long nsImapGetMailAccountUrl = 0x0000000A;
  const long nsImapDiscoverChildrenUrl = 0x0000000B;
  const long nsImapDiscoverAllBoxesUrl = 0x0000000D;
  const long nsImapDiscoverAllAndSubscribedBoxesUrl  = 0x0000000E;
  const long nsImapAppendMsgFromFile = 0x0000000F;
  const long nsImapSubscribe = 0x00000010;
  const long nsImapUnsubscribe = 0x00000011;
  const long nsImapRefreshACL  = 0x00000012;
  const long nsImapRefreshAllACLs  = 0x00000013;
  const long nsImapListFolder  = 0x00000014;
  const long nsImapUpgradeToSubscription = 0x00000015;
  const long nsImapFolderStatus  = 0x00000016;
  const long nsImapRefreshFolderUrls = 0x00000017;
  const long nsImapEnsureExistsFolder = 0x00000018;
  const long nsImapOfflineToOnlineCopy = 0x00000019;
  const long nsImapOfflineToOnlineMove = 0x0000001A;
  const long nsImapVerifylogon = 0x0000001B;
  // it's okay to add more imap actions that require us to
  // be in the authenticated state here without renumbering
  // the imap selected state url actions. just make sure you don't
  // set the high bit...

  // nsImapSelectedState urls. Note, the high bit is always set for
  // imap actions which require us to be in the selected state
  const long nsImapSelectFolder  = 0x10000002;
  const long nsImapLiteSelectFolder = 0x10000003;
  const long nsImapExpungeFolder = 0x10000004;
  const long nsImapMsgFetch  = 0x10000018;
  const long nsImapMsgHeader = 0x10000019;
  const long nsImapSearch  = 0x1000001A;
  const long nsImapDeleteMsg = 0x1000001B;
  const long nsImapDeleteAllMsgs = 0x1000001C;
  const long nsImapAddMsgFlags = 0x1000001D;
  const long nsImapSubtractMsgFlags  = 0x1000001E;
  const long nsImapSetMsgFlags = 0x1000001F;
  const long nsImapOnlineCopy  = 0x10000020;
  const long nsImapOnlineMove  = 0x10000021;
  const long nsImapOnlineToOfflineCopy = 0x10000022;
  const long nsImapOnlineToOfflineMove = 0x10000023;
  const long nsImapMsgPreview = 0x10000024;
  const long nsImapBiff  = 0x10000026;
  const long nsImapSelectNoopFolder  = 0x10000027;
  const long nsImapAppendDraftFromFile = 0x10000028;
  const long nsImapUidExpunge = 0x10000029;
  const long nsImapSaveMessageToDisk = 0x10000030;
  const long nsImapOpenMimePart = 0x10000031;
  const long nsImapMsgDownloadForOffline  = 0x10000032;
  const long nsImapDeleteFolderAndMsgs = 0x10000033;
  const long nsImapUserDefinedMsgCommand = 0x10000034;
  const long nsImapUserDefinedFetchAttribute = 0x10000035;
  const long nsImapMsgFetchPeek = 0x10000036;
  const long nsImapMsgStoreCustomKeywords = 0x10000037;
```

How messages get to folder:

nsImapMailFolder->UpdateFolder() causes a SELECT.
On the protocol side, the select does it's thing then sends a list of UIDs back to the folder via UpdateImapMailboxInfo().


