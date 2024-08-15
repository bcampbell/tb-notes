# Extra TB code style guide items beyond the M-C style


## Bug references

We should choose a standard way to reference bugs in code comments.
e.g.
```
// Slated for removal. See Bug 1848476.
```
or
```
// Slated for removal. See https://bugzilla.mozilla.org/show_bug.cgi?id=1848476.
```
?

## Async fns in C++ (using listeners/callbacks)

For functions which start operations which later invoke callbacks/listener objects:

1. The kickoff function should _not_ call any callbacks before it returns.
2. If the kickoff function fails, no callbacks should ever be called (i.e. the operation is never even started).

Example - see implementations of `nsIMsgPlugableStore.asyncScan()`.

Often, it's convenient to just have error handling in the callback, rather than duplicate it after a failing kick-off function.
To do this, the kickoff function can just return `NS_OK`, but use `NS_DispatchToMainThread(NS_NewRunnableFunction(...))` or similar to defer a call to the callback which then handles the error.

Rationale: prevents a whole set of subtle errors.


## Listener fns which take a status shouldn't just blindly return that status

BAD:
```
nsresult FooListener::OperationComplete(nsresult status)
{
  if (NS_FAILED(status)) {
    ...
    doCleanupStuff();
    ...
  }
  return status;
}
```
OperationComplete() can fail, even if it successfully cleaned up!

GOOD:
```
nsresult FooListener::OperationComplete(nsresult status)
{
  if (NS_FAILED(status)) {
    ...
    nsresult rv = doCleanupStuff();
    NS_ENSURE_SUCCESS(rv);
    ...
  }
  return NS_OK;
}
```

Rationale: If a listener fn handles cleanup when an error has occurred, then
if that cleanup is successful, the listener function was a success!

## Avoid using public inheritance for implementation details

The current codebase exposes a lot of things via inheriance which are really just implementation details.
For example, I challenge anyone to try and explain to me which inherited classes of nsMsgProtocol are really part of the public interface and which are implementation details...

Alternative is to use utility listener objects with lambdas.
See comm/mailnews/base/src/UrlListener.h for an example.
But lambda-based solutions come with their own issues (scoping gets tricky), so discretion is advised.

In simple cases public inheritance is, in fact, simpler.


## XPCOM methods which have 'out' params

```
- If a call succeeds (NS_SUCCEEDED(rv)), it must guarantee that all `out` params are set, not left at their initial values.
- If a call fails (NS_FAILED(rv)), then all bets are off - any `out` params should be considered undefined.
```

Rationale: A failing returncode should be considered as if an exception had been thrown (literally true in JS!).

## Naming classes in C++/Rust

I _think_ the consensus is:
- Drop the `ns` prefix for concrete classes.
- Keep `nsI` for interfaces.

## Capitalisation for acronyms

- `thingURL` or `thingUrl`?
- `msgID` or `msgId`?



