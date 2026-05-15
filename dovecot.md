# Setting up a local test dovecot server


We want to run as a normal user (not root). Instructions here:

https://doc.dovecot.org/2.4.3/core/config/rootless.html#rootless-installation


## Installation

Source tarballs at:

https://dovecot.org/releases/

Or via Git:
```
$ git clone https://github.com/dovecot/core.git dovecot
````


Prerequisites:
```
$ sudo apt-get install libcrypt-dev libssl-dev liblua5.3-dev
```

Note: liblua5.5 not supported (as of dovecot 2.4.3). lua_newstate() gains an extra param in 5.5.


Configure, build and install:
```
$ ./configure --prefix=$HOME/dovecot
$ make
$ make install
```

## Configuration

### Add Capabilities

Lets you use the standard ports, even while running as a non-root user.

See https://doc.dovecot.org/2.4.3/core/config/rootless.html#add-capabilities


### Config files

See https://doc.dovecot.org/2.4.3/core/config/rootless.html#configuration


~/dovecot/etc/dovecot/dovecot.conf
```
dovecot_config_version = 2.4.3
dovecot_storage_version = 2.4.3
!include_try conf.d/*.conf

protocols {
  imap = yes
  lmtp = yes
}

mail_home = /home/ben/crap/mail/%{user}
mail_driver = sdbox
mail_path = ~/mail

#mail_uid = 1000
#mail_gid = 1000

# By default first_valid_uid is 500. If your vmail user's UID is smaller,
# you need to modify this:
#first_valid_uid = uid-number-of-vmail-user

namespace inbox {
  inbox = yes
  separator = /
}

default_internal_user = ben
default_login_user = ben
default_internal_group = ben

ssl = no


passdb passwd-file {
  default_password_scheme = plain
  passwd_file_path = /home/ben/crap/mail/passwd
}

# for debugging/logging
auth_verbose = yes
log_path = /home/ben/crap/mail/dovecot.log
debug_log_path = /home/ben/crap/mail/dovecot-debug.log
info_log_path = /home/ben/crap/mail/dovecot-info.log
```

passwd file:
```
bob:{plain}pass:1000:1000
```


### Feeding mail into dovecot

```
$ cat foo.eml | ~/dovecot/libexec/dovecot/dovecot-lda -e -d bob
```

https://doc.dovecot.org/2.4.3/core/man/dovecot-lda.1.html




