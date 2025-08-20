
Use loopback to create a virtual drive in a file.

eg - create a 100MB ntfs drive in `/tmp/ntfs_mnt`:

```
$ cd /tmp
$ dd if=/dev/zero of=loopback.img bs=1M count=100
$ sudo losetup /dev/loop0 /tmp/loopback.img
$ sudo mkfs.ntfs /dev/loop0
$ mkdir ntfs_mnt
$ sudo mount /dev/loop0 ntfs_mnt

```

detach:
```
$ sudo umount ntfs_mnt
$ sudo losetup -d /dev/loop0
```


