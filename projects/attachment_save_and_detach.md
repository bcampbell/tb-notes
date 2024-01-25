The nsIMessenger attachment functions seem a little convoluted.


saveAllAttachments()
 - Don't prompt for filenames. Make the caller pass in destination path(s) up front
 - Single messageUri rather than array? (all attachments must be from same message, right?)
 - Rename to saveAttachments()
 - Make sure it works with multiple attachments
 - Add unit tests (there's a mochitest, but no xpcshell test)

detachAllAttachments()
 - Rename to detachAttachments().
 - Ditch saveFirst option (make the caller do it!)
 - Add a listener to trigger when complete.
 - Single messageUri rather than array? (all attachments must be from same message, right?)
 - No prompting (not sure if it does or not right now).
 - User to pass in list of file urls for previously-detached attachments (to fill out X-Mozilla-External-Attachment-URL headers in the deleted attachements).
 - Make sure it works with multiple attachments
 - Add unit tests (there's a mochitest, but no xpcshell test)

detachAttachmentsWOPrompt()
 - Ditch entirely, use detachAttachments() instead.

detachAttachment()
 - Ditch entirely, use detachAttachments() instead.

saveAttachment()
 - Ditch entirely, use saveAttachments() instead.


See also:
  - Bug 1578801 -Provide an additional save path attribute in function call nsMessenger::DetachAllAttachments()

