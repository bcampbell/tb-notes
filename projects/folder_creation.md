# Folder creation

## The issue

We've still got a bunch of odd holdovers from the old folders-as-RDF-resources setup.
In particular, there's a concept where "dangling", parentless folders are created and used for various things. This is bad, as those folders are not in a valid state for most operations.

Because of all this, the path by which nsIMsgFolder objects come into existence is very convoluted and specific to folder type.

## Goal

- Simple folder creation steps.
- No "dangling" (unparented) folders.
- Only ever one nsIMsgFolder object representing a folder.
- Clear up naming rules and implementation for folder URLs, pretty names, file paths.

## Steps

- Remove all GetOrCreateFolder() calls. Use GetExistingFolder() where possible, or perform explict folder creation.
- Rationalise the various folder-discovery processes
  - Use msgStore to discover local folder paths
  - Simplify IMAP discovery process
- Remove folder lookup service. Just traverse the account/folder tree instead.

## Relevant bugs

Bug 1679333	- Remove support for dangling (unparented) folders

Bug ??? - Get rid of folder lookup service altogether.

Bug 124287 (folders-with-special-characters) - [Meta] Problems with folders having names with illegal(or special) characters or special name

