# nsIMsgPluggableStore API refactor

## The issue

The nsIMsgPluggableStore interface is currently tightly coupled with both folder and msgDB.
This makes it really hard to reason about the store itself, and to write solid and dimple unit tests.


## Goal

- should be able to create a msgStore in isolation, for unit tests, conversions etc..
- Write a suite of solid unit tests to really exercise the msgStore.
- Better data conversion between message stores (use the API!).


## Steps

- use storeToken exclusively to refer to messages.
- move msgDB & folder stuff out into folder code

## Undecided

- how does the potential single-message-appearing-in-multiple folders aspect bear out here?


## Relevant bugs

Bug 1714472	[meta] Decouple nsIMsgPluggableStore from nsIMsgFolder and nsIMsgDatabase


