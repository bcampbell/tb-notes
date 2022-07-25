
# which source files included in build?

moz.build files in subdirs control which files are built

# ctags setup

in $HOME/.ctags:

    --langdef=idl
    --langmap=idl:.idl
    --regex-idl=/interface\s+([a-zA-Z0-9_]+)\s*:/\1/d,definition/

[from: https://github.com/majutsushi/etc/blob/master/ctags]


invocation:

    $ ctags -R --languages=C,C++,xpidl --exclude=obj-x86_64-pc-linux-gnu --exclude=objdir-tb-asan --exclude=third-party --exclude=node_modules --exclude=.hg .

# cleanup .orig and .rej files from dirs

    $ find . -name "*.orig" -delete
    $ find . -name "*.rej" -delete

# static analysis on outgoing files in hg:

  $ ./mach static-analysis check --outgoing

