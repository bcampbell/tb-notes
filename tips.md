
# Try Server

Can't seem to get `../mach try ...` to push to correct repo.
Always seems to push to the default hg.mozilla.org/try server instead.

commit message with try syntax, and a manual push works eg:

    $ cd comm
    $ hg qnew -m "try: -b do -p linux64,macosx64,win32 -u all" try
    $ hg push -f -r tip cc-try && hg qpop && hg qdelete try

tests:
    -u all
    -u mozmill
    -u none

platforms:
    -p linux,linux64,macosx64,win32,win64

assumes [paths] part in C-C/.hg/hgrc contains:

    cc-try = ssh://hg.mozilla.org/try-comm-central


To do a try build with changesets from both M-C and C-C:

make sure the M-C try server alias is set up in M-C/.hg/hgrc:

    try = ssh://hg.mozilla.org/try

Push the changeset(s) you want to M-C:

    $ hg push -r <top rev to push> -f try

Edit C-C`/.gecko_rev.yml` to set the M-C rev:

    -GECKO_HEAD_REPOSITORY: https://hg.mozilla.org/mozilla-central
    -GECKO_HEAD_REF: default
    +GECKO_HEAD_REPOSITORY: https://hg.mozilla.org/try
    +GECKO_HEAD_REF: <your rev here>

Then do a C-C try build as usual.




# which source files included in build?

moz.build files in subdirs control which files are built

# ctags setup

in $HOME/.ctags:

    --langdef=idl
    --langmap=idl:.idl
    --regex-idl=/interface\s+([a-zA-Z0-9_]+)\s*:/\1/d,definition/

invocation:

    $ ctags -R --languages=C,C++,idl --exclude='obj-x86_64-pc-linux-gnu/*' --exclude='*dist\/include*' --exclude='*[od]32/*' --exclude='*[od]64/*' --exclude '.hg' .

# cleanup .orig and .rej files from dirs

    $ find . -name "*.orig" -delete
    $ find . -name "*.rej" -delete


