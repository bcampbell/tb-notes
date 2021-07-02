From [Bug 1700779](https://bugzilla.mozilla.org/show_bug.cgi?id=1700779):


nsIFolderListener:

- can be registered either to individual folders, or globally, to the nsIMsgMailSession.
- nsIFolderListener notifications generally originate inside the folder implementations, using the `nsIMsgFolder.Notify*` functions.

nsIMsgFolderListener:

- defines listener callbacks for global registration with nsIMsgFolderNotificationService.
- nsIMsgFolderNotificationService notifications are invoked from a bunch of places.
- are registered along with a set of flags, so you just receive the notifications you're interested in, and the rest are ignored.


