# Assorted notes on copying messages


nsIMsgCopyService is a sort of front end for copying messages about, without worrying too much about the folder types involved.

The copy functions usually support moving too (via a bool param).

can copy/move:
- messages
- file messages (RFC format)
- folders

nsMsgCopyService delegates most of the work to the folder implementations.

copying is async, uses nsIMsgCopyServiceListener callbacks.



For copying between different nsIMsgIncomingServers, messages must be streamed (ie manually copied).
For the same server, shortcuts may be used (eg renaming files).

