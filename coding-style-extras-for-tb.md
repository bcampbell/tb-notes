# Extra TB code style guide items beyond the M-C style


## Bug references

```
// Slated for removal. See Bug 1848476.
```
or
```
// Slated for removal. See https://bugzilla.mozilla.org/show_bug.cgi?id=1848476.
```
?

## Async fns in C++ (using listeners/callbacks)

1. The kickoff function should _not_ call any callbacks before it returns.
2. If the kickoff function fails, no callbacks should ever be called (i.e. the
operation is seen as never having even started).

Example - see implementations of `nsIMsgPlugableStore.asyncScan()`.

## Listener fns which take a status shouldn't just blindly return that status

BAD:
```
nsresult FooListener::OperationComplete(nsresult status)
{
  if (NS_FAILED(status)) {
    ...
    status = doCleanupStuff();
    ...
  }
  return status;
}
```

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

https://www.hyrumslaw.com/

I challenge anyone to try and explain to me which inherited classes of nsMsgProtocol are really part of the public interface and which are implementation details...

Alternative is to use utility listener objects with lambdas.
See comm/mailnews/base/src/UrlListener.h for an example.

But lambda-based solutions they come with their own issues (scoping), so discretion
is advised.


## XPCOM methods which have 'out' params

```
- If a call succeeds (NS_SUCCEEDED(rv)), it must guarantee that all `out` params are set, not left at their initial values.
- If a call fails (NS_FAILED(rv)), then all bets are off - any `out` params should be considered undefined.
```

A failing returncode should be considered as if an exception had been thrown (literally true in JS!).
