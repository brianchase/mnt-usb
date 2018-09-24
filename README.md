# mnt-dev

## About

This Bash script mounts and unmounts removable devices, such as USB
thumb drives. Features:

* Convenient menus and command line options.
* Support for mounting and unmounting encrypted devices with
[cryptsetup](https://gitlab.com/cryptsetup/cryptsetup/).
* Flexible use of [sudo](https://www.sudo.ws/) for commands needing
elevated permissions.
* Dynamic default values for mount points and device mappings.
* Detection of devices with multiple mount points.

## How It Works

If the script detects just one connected device (on `/dev/sdb` through
`/dev/sdz`), it checks whether the device is mounted. If it's mounted,
the script asks to unmount it. If it's not mounted, the script asks to
mount it.

If the script detects more than one device, it lists them and ask
which ones to mount or unmount. You can select individual devices or
chose to mount all the ones that aren't mounted or to unmount all the
ones that are. It then gives you the option of returning to the menu,
which it updates to reflect the current status of each device.

By default, the script mounts all devices in `/mnt` according to its
name in `/dev`. For example, it mounts `/dev/sdb1` in `/mnt/sdb1`,
creating the directory in `/mnt` if necessary. Similarly, if it
detects that a device has an encrypted file system, it uses
[cryptsetup](https://gitlab.com/cryptsetup/cryptsetup/) to open the
device in `/dev/mapper` under the device's name. For example, it opens
`/dev/sdb1` on `/dev/mapper/sdb1`, then mounts it on `/mnt/sdb1`.

The script overrides these defaults if the paths are taken. If
`/mnt/sdb1` is already a mount point or any file other than an empty
directory, it tries `/mnt/sdb1-2`, then `/mnt/sdb1-3`, and so on,
until it finds a suitable path. The same goes for map points: If
another encrypted device is open on `/dev/mapper/sdb1`, it checks
`/dev/mapper/sdb1-2`, and so on.

After unmounting a device, the script removes its mount point and, if
it's encrypted, uses
[cryptsetup](https://gitlab.com/cryptsetup/cryptsetup/) to close its
map point. Neither path needs to be where the script would ordinarily
put them. So long as it finds a device in the first place, it should
be able to deal with them.

You may run the script without options and follow the prompts or
run it with these options:

```
$ mnt-dev.sh [mount|unmount|umount] [device|all] [now]
```

The options `mount`, `unmount`, and `umount` (the latter two are
synonymous) require the name of a particular device or `all`. To mount
`/dev/sdb1` in this way:

```
$ mnt-dev.sh mount /dev/sdb1
```

To unmount it, use `unmount` or `umount`:

```
$ mnt-dev.sh unmount /dev/sdb1
```

In fact, `unmount` and `umount` also take mount points or map points.
Assuming default values, then, and no conflicts with other devices –
and also, for completeness, that `/dev/sdb1` is encrypted – the
following have the same effect:

```
$ mnt-dev.sh unmount /dev/sdb1
$ mnt-dev.sh unmount /mnt/sdb1
$ mnt-dev.sh unmount /dev/mapper/sdb1
```

Using `mount all` tells the script to mount all connected devices that
aren't mounted:

```
$ mnt-dev.sh mount all
```

Using `unmount all` or `umount all` tells the script to unmount all
connected devices that are mounted:

```
$ mnt-dev.sh umount all
```

Adding `now` to the previous commands bypasses requests for
confirmation. Unless it encounters an error, the script will silently
mount or unmount the relevant devices.

Keep in mind that using `now` isn't always a good idea. The
confirmation prompt names the device and its mount point. You may need
that information to keep track of what you're doing.

## Customizing

If you prefer a different mount point, say, `/media`, simply change
the value of `PNT` on line six of the script:

```
PNT="mnt"
```

If your system has more than one internal drive, you may need the
script to look for connected devices starting at `/dev/sdc` or higher.
In that case, find the `readarray` for `DevArr1` in the function
`dev_arrays`:

```
readarray -t DevArr1 < <(lsblk -dpno NAME,FSTYPE /dev/sd[b-z]* 2>/dev/null | awk '{if ($2) print $1;}')

```

Change `/dev/sd[b-z]*` as necessary – for example, to `/dev/sd[c-z]*`
to treat `/dev/sdc` as the first possible connected device.

## License

This project is in the public domain under [The
Unlicense](https://choosealicense.com/licenses/unlicense/).

## Requirements

* [cryptsetup](https://gitlab.com/cryptsetup/cryptsetup/) (for encrypted devices)
* [sudo](https://www.sudo.ws/) (for nonroot users running mount,
umount, cryptsetup, mkdir, and rmdir)

