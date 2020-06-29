# IMAP - issues

## nsImapUrl is stateful.

Not just in IMAP - all the nsMsgMailNewsUrl-derived classes are affected.

nsImapUrl seems to be used as a handle to a request, where it would be more
appropriate for nsIChannel to be used instead.

nsIUrlListener is analogous with nsIRequestObserver?

## nsImapProtocol needlessly implements nsIChannel

nsIMapProtocol is currently used to represent both an IMAP connection
(via socket) and a specific request.

But in order to queue up operations, IMAP commands return nsImapMockChannel
objects (albeit hidden inside nsImapUrl objects).

The nsIChannel support in nsImapProtocol needlessly complicatesto implement nsIChannel, given that
IMAP should always be returning nsImapMockChannel instead...

## Suggestions:

Remove nsIChannel support from nsImapProtocol.
 (probably requires a lot of work in nsMsgProtocol too).

Rename nsImapProtocol to nsImapConnection?

Break out nsImapMockChannel into it's own source files.

Rename nsImapMockChannel to nsImapChannel.

Promote nsImapChannel to be the single nsIChannel implementation for IMAP.

Make nsImapUrl stateless - it should be merely a helper for creating/mutating
"imap://" urls.

nsImapChannel should contain all the state for the given IMAP operation(s) it
represents.

nsImapChannels are queued by nsImapConnection and sent
sequentially, as the connection is available.


