# MOZ_TRY is ace

It can be used for old-style functions which return `nsresult`.

But it can also be to call functions which return `Result<T, nsresult>`, yielding the T, or exiting with the failing nsresult.


Example:
```
// Old-school.
nsresult TheAnswer(int* ret) {
    *ret=42;
    return gSunSpot ? NS_ERROR_UNEXPECTED;
}

// Fancypants rust style!
Result<nsCString, nsresult> TheQuestion() {
    if (gSunSpot) {
        return Err(NS_ERROR_UNEXPECTED);
    } else {
        return Ok("What do you get if you multiply six by nine?"_ns);
    }
}

nsresult doStuff() {
    int a;
    MOZ_TRY(TheAnswer(&a));

    nsCString q = MOZ_TRY(TheQuestion());

    return NS_OK;
}


```


