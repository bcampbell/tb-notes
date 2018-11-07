
# Try Server

Can't seem to get `../mach try ...` to push to correct repo.
Always seems to push to the default hg.mozilla.org/try server instead.

commit message with try syntax, and a manual push works eg:

    $ cd comm
    $ hg qnew -m "try: -b do -p linux64 -u all" try
    $ hg push -f -r tip cc-try && hg qpop && hg qdelete try

tests:

    -u all
    -u mozmill
    -u none

assumes [paths] part in .hg/hgrc contains:

    cc-try = ssh://hg.mozilla.org/try-comm-central

# which source files included in build?

moz.build files in subdirs control which files are built

