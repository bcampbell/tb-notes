
# which source files included in build?

moz.build files in subdirs control which files are built

# ctags setup

`universal-ctags` is probably the one to use.
It's a maintained version of `exuberant-ctags`.

In $HOME/.config/ctags/xpidl.ctags:

```
--langdef=xpidl
--langmap=xpidl:.idl
--regex-xpidl=/^[[:blank:]]*interface[[:space:]]+([a-zA-Z0-9_]+);$/\1/p,prototype/
--regex-xpidl=/^[[:blank:]]*interface[[:space:]]+([a-zA-Z0-9_]+)[[:space:]]+(:[[:space:]]*[^{]+[[:space:]]*)?/\1/i,interface/
--regex-xpidl=/^.*[[:blank:]]+attribute[[:space:]]+([a-zA-Z0-9_]+)[[:space:]]+([a-zA-Z0-9_]+);/\2/a,attribute/
--regex-xpidl=/^.*native[[:blank:]]+([a-zA-Z0-9_]+)\(/\1/t,type/
--regex-xpidl=/^.*(void|boolean|octet|short|long|long[[:blank:]]+long|unsigned[[:blank:]]+short|unsigned[[:blank:]]+long|unsigned[[:blank:]]+long[[:blank:]]+long|float|double|char|wchar|string|wstring|nsrefcnt)[[:blank:]]+([a-zA-Z0-9_]+)\(/\2/o,operation/
```

(from: https://github.com/janlarres/etc/blob/main/dotfiles/ctags)

invocation:

```
    $ ctags-universal -R --languages=C,C++,xpidl --exclude=obj-x86_64-pc-linux-gnu --exclude=third-party --exclude=node_modules --exclude=.hg .
```

better javascript config for ctags?:

https://medium.com/adorableio/modern-javascript-ctags-configuration-199884dbcc1

# cleanup .orig and .rej files from dirs

```
    $ find . -name "*.orig" -delete
    $ find . -name "*.rej" -delete
```

# static analysis on outgoing files in hg:

```
  $ ./mach static-analysis check --outgoing
```

# build compile_commands.json

For use by the clang LSP:

```
./mach build-backend --backend=CompileDB
ln -s obj-x86_64-pc-linux-gnu/compile_commands.json compile_commands.json
```
