
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

platforms:
    -p linux,linux64,macosx64,win32,win64

assumes [paths] part in .hg/hgrc contains:

    cc-try = ssh://hg.mozilla.org/try-comm-central

# which source files included in build?

moz.build files in subdirs control which files are built

# ctags setup

in $HOME/.ctags:

    --langdef=idl
    --langmap=idl:.idl
    --regex-idl=/interface\s+([a-zA-Z0-9_]+)\s*:/\1/d,definition/

invocation:

    $ ctags -R --languages=C++,idl --exclude='obj-x86_64-pc-linux-gnu/*' --exclude='*dist\/include*' --exclude='*[od]32/*' --exclude='*[od]64/*'

