# URI notes



## encoding issues:

- Local folder URIs parts are percent-encoded UTF-8 (as per RFC recommendation).
- Local folder URIs still have some issues with non-ascii chars.
- IMAP folder URIs are not percent-encoded (eg spaces are verbatim).

## places that store URIs

These would need to be migrated (or tolerated) if/when URI encoding is fixed:

- prefs.js
- gloda (global-messages-db.sqlite)
- virtual folders (virtualFolders.dat)
- folderTree.json
- session.json
- others?



