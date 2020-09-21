# NNTP cleanups

- make nsNNTPProtocol NOT implement nsIChannel (a more fundamental base nsMsgProtocol change).
- use nsNntpMockChannel as the nsIChannel implementation, even when a real connection is available! (maybe rename it to nsNNTPChannel?)
- maybe a separate class to represent LoadUrl() operations in progress?
- maybe deXPCOMify and kill nsINNTPProtocol?
- work out what the difference is between LoadUrl() and LoadNewsUrl().
- can LoadNewsUrl() be used for nsIChannel operations? If so kill that and use the proper channel interfaces!


