
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


