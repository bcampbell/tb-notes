# Assorted notes on copying/moving/deleting messages


nsIMsgCopyService is a sort of front end for copying messages about, without worrying too much about the folder types involved.

The copy functions usually support moving too (via a bool param).

can copy/move:
- messages
- file messages (RFC format)
- folders

nsMsgCopyService delegates most of the work to the folder implementations.

Copying is async, uses nsIMsgCopyServiceListener callbacks.

For copying between different nsIMsgIncomingServers, messages must be streamed (ie manually copied).
For operations within the same server, the mailstore might be able to provide
shortcuts (eg maildir can perform moves by just renaming files).

