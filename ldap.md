
A public LDAP server to test against, from
[Bug 1574712](https://bugzilla.mozilla.org/show_bug.cgi?id=1574712#c0):

Configure an LDAP server:
Options, Composition, Addressing:
Click "Directory Server", Edit Directories, and Add "Adams":
Name: Adams, Hostname: ldap.adams.edu, Base DN: ou=people,dc=adams,dc=edu
One can now go to the address book, click on Adams on the left, and search for Alvarez. "Alvarez, Leslie" comes up. Close the address book.

Commandline LDAPS examples:

    $ ldapsearch -v -x -H "ldaps://ldap.adams.edu" -b ou=people,dc=adams,dc=edu -s sub "(cn=*)" cn mail sn

    $ ldapsearch -v -x -H "ldaps://ldap.adams.edu" -b ou=people,dc=adams,dc=edu -s sub "(surname=Abeyta)" givenname
