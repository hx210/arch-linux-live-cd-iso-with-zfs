# Arch Linux Archiso builder with zfs support

This repository contains a simple, free as in freedom, wrapper to automate the steps mentioned in the [arch linux wiki](https://wiki.archlinux.org) for the [zfs installation](https://wiki.archlinux.org/index.php/ZFS#Installation) and the [archios package installation](https://wiki.archlinux.org/index.php/Archiso#Installing_packages).

All you need to do is to execute the [build.sh](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/blob/master/build.sh) and follow the instructions.

You can run this script either as root or as normal user. If you are working as normal user, you need to be able to execute things with the sudo command.

All needed packages where installed automatically. At the end, this script will outputs the path to the created iso file.

At the end, you only need to dd the iso to your favorit usb drive or burn it on an optical disk.

# History

* upcomming
    * @todo
        * beautify the output
        * add option to dd it to a sdX device
* [1.1.0](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/tree/1.1.0) - released at 14.05.2016
    * added [README.md](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/blob/master/README.md)
    * renamed "build" directory to "dynamic_data" to easy up execution of "build.sh"
* [1.0.0](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/tree/1.0.0) - released at 12.05.2016

# Final Words

Star it if you like it :-). Add issues if you need it. Pull patches if you enjoy it. Write a blog entry if use it. Make a [donation](https://gratipay.com/~stevleibelt) if you love it :-].
