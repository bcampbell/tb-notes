
# Try Server

Can't seem to get `../mach try ...` to push to correct repo.
Always seems to push to the default hg.mozilla.org/try server instead.

commit message with try syntax, and a manual push works eg:

    $ hg qnew -m "try: -b do -p linux64 -u none" try
    $ hg push -f -r tip cc-try && hg qpop && hg qdelete try

(assumes `cc-try = ssh://<USERNAME>@hg.mozilla.org/try-comm-central` in .hgrc)

