# Try Server

##Setup

assumes [paths] part in C-C/.hg/hgrc contains:

    cc-try = ssh://hg.mozilla.org/try-comm-central


## Submitting a try build

tests:
    -u all
    -u mozmill
    -u none

```
    $ hg push-to-try -s ssh://hg.mozilla.org/try-comm-central -m "try: -b do -p all -u all"
```

https://developer.thunderbird.net/thunderbird-development/fixing-a-bug/try-server#try-syntax

## Try build with changesets from both M-C and C-C

make sure the M-C try server alias is set up in M-C/.hg/hgrc:

    try = ssh://hg.mozilla.org/try

Push the changeset(s) you want to M-C:

    $ hg push -r <top rev to push> -f try

Edit C-C`/.gecko_rev.yml` to set the M-C rev:

    -GECKO_HEAD_REPOSITORY: https://hg.mozilla.org/mozilla-central
    -GECKO_HEAD_REF: default
    +GECKO_HEAD_REPOSITORY: https://hg.mozilla.org/try
    +GECKO_HEAD_REF: <your rev here>

Then submit a C-C try build as usual.

