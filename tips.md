
# which source files included in build?

moz.build files in subdirs control which files are built

# ctags setup

`universal-ctags` is probably the one to use.
It's a maintained version of `exuberant-ctags`.

in $HOME/.ctags.d/xpidl.ctags:

    --langdef=xpidl
    --langmap=xpidl:.idl
    --regex-xpidl=/interface\s+([a-zA-Z0-9_]+)\s*:/\1/d,definition/

[from: https://github.com/majutsushi/etc/blob/master/ctags]


invocation:

    $ ctags -R --languages=C,C++,xpidl --exclude=obj-x86_64-pc-linux-gnu --exclude=objdir-tb-asan --exclude=third-party --exclude=node_modules --exclude=.hg .

better javascript config for ctags?:

https://medium.com/adorableio/modern-javascript-ctags-configuration-199884dbcc1

# cleanup .orig and .rej files from dirs

    $ find . -name "*.orig" -delete
    $ find . -name "*.rej" -delete

# static analysis on outgoing files in hg:

  $ ./mach static-analysis check --outgoing

