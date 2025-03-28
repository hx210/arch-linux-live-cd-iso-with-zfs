# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

Changelogs can easily created with the following commands.
```bash
# List all tags created by creation date
git tag --sort=-creatordate

TAG_CREATED_FROM="<string: major.minor.bugfix>"
git log ${TAG_CREATED_FROM}..HEAD | grep '^   ' | trim
```

## Open

### To Add

* Add support for running GitHub-Actions [locally](https://www.freecodecamp.org/news/how-to-run-github-actions-locally/)
* Add support for [remove packages](https://wiki.archlinux.org/title/User:LenHuppe/ZFS_on_Archiso/)
* Add usage for `kernel.archzfs.com`
  * [Link](https://end.re/blog/ebp036_archzfs-repo-for-kernels/)
  * [Source](https://github.com/archzfs/archzfs/issues/467#issuecomment-1332029677)
* Add flag `-c|--cleanup` for `build.sh`

### To Change

* Reduce the iso size since this is way about 2 GiB while the official image has a size of 1.1 GiB by checking:
  * Compare installed packages (mount/start official iso and run `pacman -Qq` and do the same on our build)
  * Check if we can remove HOOKS in `airootfs/etc/mkinitcpio.conf`
  * Check if official image also has that high amount of firmware
  * Check if lts image contains non-lts kernel by mistake
  * Check `releng/packages.x86_64` if we really need all in there
* Apply [shellcheck](https://github.com/koalaman/shellcheck) to all scripts
* Manipulate `dynamic_dat/releng/profiledef.sh` before running the iso build process
  * [issue/9](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/issues/9)
  * [official profiledef.sh documentation](https://gitlab.archlinux.org/archlinux/archiso/-/blob/master/docs/README.profile.rst)
  * [example of an manipulated file](https://github.com/HougeLangley/archzfs-iso/blob/master/profiledef.sh)
  * Things to change
    * `iso_name`
    * `iso_label`
    * `iso_publisher`
    * `iso_application`
    * `file_permissions`
      * own git repros in user home should have 775
* Recheck GitHub actions using things like [this](https://github.com/ossf/education/pull/36/files) as an example
* Validate if we can implement the "use older kernel" feature from [here](https://github.com/eoli3n/archiso-zfs/blob/master/init) to prevent failing builds when the archzfs package is not up to date to the latest linux kernel

## Unreleased

### Added in unreleased

* Added arguments to [run the iso](run_iso.sh) script, check out `run_iso.sh`
* Added environment variable `ISO_BOOT_TYPE` to prevent question about "uefi or bios" when try to [run the iso](run_iso.sh)
* Added `last_build_date*.txt` to [gitignore](.gitignore)

### Changed in unreleased


## [3.1.0](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/tree/3.1.0) - 20250207

### Added in 3.1.0

* Added automatic use docker if available in [build.sh](build.sh)
* Added cleanup section in build process to reduce iso size
* Added removal of `.git` directories for all "batteries included" scripts
* Added usage of .env to [upload_iso](upload_iso.sh)

### Changed in 3.1.0

* Updated build section
* Fixed invalid user
* Fixed issue that `linux-20*.iso` was not renamed correctly

## [3.0.0](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/tree/3.0.0) - 20241118

### Added in 3.0.0

* Added content of repository [bht](https://github.com/ezonakiusagi/bht) below `software`
* Added `compose.yml` to be able to build iso inside a privileged docker container 
* Added links to openssf and badge
* Added packages mailx, ksh and nmon
* Added [SECURITY.md](SECURITY.md)
* Added script `create_efibootmgr_entry.sh` to ease up fixing lost `ZFSBootMenu` entries
* Added script `start_sshd.sh`
* Added section in `.env` to add or to remove packages
* Added support for `-l|--lts` as kernel in [upload_iso.sh](upload_iso.sh)

### Changed in 3.0.0

* Changed default values for [replace_zfsbootmenu.sh](source/replace_zfsbootmenu.sh)
  * Default path for old ZBM is now `/mnt/efi...`
  * Default path for new ZBM is now basepath of the called script
* Moved from build image `archlinux:latest` to `archlinux/archlinux:latest` to fix issues like [archinstal#2443](https://github.com/archlinux/archinstall/issues/2443)
* Moved archzfs mirrorlist to dedicated file `/etc/pacman.d/archzfs`

### Breaking Changes in 3.0.0

* Instead of different configuration files below `<project_root>/configuration/`, there is now a unified `.env` file and a `.env.dist`
  * Migration should work by executing `cat configuration/*.sh > .env`

## [2.11.1](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/tree/2.11.1) - 20231111

### Changed in 2.11.1

* Fix invalid broken ZFSBootMenu EFI (Portable) downloadpath

## [2.11.0](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/tree/2.11.0) - 20231111

### Added in 2.11.0

* Added dedicated iso building workflows for
  * `lts_dkms`
  * `lts_no_dkms`
  * `no_lts_dkms`
  * `no_lts_no_dkms`
* Added step to download latest zfsbootmenu.EFI file
* Added script `replace_zfsbootmenu.sh` to ease up updating a system to the latest zfsbootmenu

### Changed in 2.11.0

* Change default git workflow job to `linux-lts-dkms`

## [2.10.0](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/tree/2.10.0) - 20230526

### Added in 2.10.0

* Added build option to use git package for `zfs-dkms-git` or `zfs-linux-git`
  * Either use `USE_GIT_PACKAGE` in the configuration file
  * Or use `build.sh -g`

## [2.9.0](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/tree/2.9.0) - 20230523

### Added in 2.9.0

* Added automatically change of `iso_name` in profiledef.sh
* Added support for `linux-lts` as done [here](https://wiki.archlinux.org/title/User:LenHuppe/ZFS_on_Archiso/), see [here](https://wiki.archlinux.org/title/Archiso#Kernel)
  * Usage: `build.sh -k 'linux-lts'` or `echo KERNEL='linux-lts' > configuration/build.sh`
* Added check if dkms build failed in the `mkarchiso` call by grep'ing the logs - Workaround for [issue/18](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/issues/18)
* Added logging to [build.sh](build.sh) into file `build.sh.log`
* Added `set -e` on [build.sh](build.sh)
* Added [arch-linux-cd-zfs-setup](https://github.com/stevleibelt/arch-linux-live-cd-zfs-setup) to the image path `root/software/arch-linux-live-cd-zfs-setup` - Mostly for debugging and the case when neither zfs-dkms nor zfs-linux is compatible with the current/latest linux kernel [e.g. see [here](https://github.com/archzfs/archzfs/issues/486)]
* Added [scorecard](https://github.com/marketplace/actions/ossf-scorecard-action) GitHub action
* Added explicit and dedicated function `_remove_file_path_or_exit`

### Changed in 2.9.0

* Changed number of available iso file check from "greater 0" to "equal 1"
* Changed place where `last_build_date.txt` is created, moved from [upload_iso.sh](upload_iso.sh) to [build.sh](build.sh)
* Updated [upload_iso.sh](upload_iso.sh) to meet the [shellcheck](https://www.shellcheck.net/)
* Updated workflow and added step that creates `configuration/build.sh`

## [2.8.1](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/tree/2.8.1) - 20230129

### Changed in 2.8.1

* Updated [sed repro index logic](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/pull/15)

## [2.8.0](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/tree/2.8.0) - 20230129

### Added in 2.8.0

* Added configuration option `ASK_TO_DUMP_ISO`, `ASK_TO_RUN_ISO` and `ASK_TO_UPLOAD_ISO`
* Added git repository [arch-linux-configuration](https://github.com/stevleibelt/arch-linux-configuration) to the image in the path `/root/software/arch-linux-configuration`
* Added git repository [downgrade](https://github.com/pbrisbin/downgrade) to the image in the path `/root/software/downgrade`
* Added git repository [general_howtos](https://github.com/stevleibelt/general_howtos) to the image in path `/root/document/general_howtos`

### Changed in 2.8.0

* Fixed not working [run_iso.sh](run_iso.sh)

## [2.7.0](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/tree/2.7.0) - 20230111

### Added in 2.7.0

* Added `touch` to update creation date of `last_build_date.txt`
* Added `git` as mandatory package to ease up using [arch-linux-configuration](https://github.com/stevleibelt/arch-linux-configuration)
* Added "possible errors" section in the readme
* Added flag `-u|--use-dkms` to use `zfs-dkms` instead of `zfs-linux`

### Changed in 2.7.0

* Changed some of the `_echo_if_be_verbose` calls by adding the variable name before outputing its content`
* Added removal of `last_build_date.txt` if exists when `upload_iso.sh` is executed
* Updated `source/pacman-init.service`
* Moved from `qemu` to `qemu-full`

## [2.6.0](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/tree/2.6.0) - 20220419

### Changed in 2.6.0

* Fixed [issue/8](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/issues/8)

## [2.5.0](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/tree/2.5.0) - 20220418

### Added in 2.5.0

* Added `-d`, `-h` and `-v` to `upload_iso.sh`
* Implemented code from [pull request/6](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/pull/6) with an additional flag "-r|--repo-index <string: last|week|month|yyyy/mm/dd>"
  * If you just provide `-r`, `week` is used
* Added [configuration file](configuration/build.sh.dist) for build.sh
* Added `-d|--dry-run` in `build.sh`

### Changed in 2.5.0

* Remove usage of `BE_VERBOSE` in `configuration/upload_iso.sh` since this is superseeded by `-v`

## [2.4.0](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/tree/2.4.0) - released at 20220330

### Added in 2.4.0

* Added if `[[ ${?} -ne 0 ]];` for each fitting command call
* Added [dump_iso.sh](dump_iso.sh) to dd a created iso
* Added check if build was successful
  * The next steps where only executed if build was successful
* Added output of flags when verbosity is enabled
* Added way more output if run in verbose mode
* Added addtional check in the step after bulding the iso to validate that an iso was build
* Added doc block to each function
* Added argument check in each function

### Changed in 2.4.0

* Fixed an issue if script is not calld as root
  * Previous to this fix, all arguments where lost (like `-f`)
* Centralized code by creating `_create_directory_of_exit` an `_remove_path_or_exit`

## [2.3.0](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/tree/2.3.0) - released at 20220328

### Added 2.3.0

* Added flag `-h | --help`
* Added flag `-f | --force`
* Added flag `-v | --verbose`

## [2.2.0](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/tree/2.2.0) - released at 20220320

### Added 2.2.0

* added the `auto_elevate_if_not_called_from_root` from [build.sh](build.sh) in [run_iso.sh](run_iso.sh)
* added [upload_iso.sh](upload_iso.sh)
  * if not available, it creates a local configuration file in [configuration](configuration)
  * if user says yes, this is executed after a successful [build.sh](build.sh)
* created [archzfs.stevleibelt.de](https://archzfs.leibelt.de/)

### Changed in 2.2.0

* Aligned release date
* Fixed link in release 2.1.0

## [2.1.0](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/tree/2.1.0) - released at 20220319

### Added in 2.1.0

* added a [CHANGELOG.md](CHANGELOG.md)
* added list of contributers

### Changed in 2.1.0

* replaced current handlig of "exit if not executed from root" with "restart script by using sudo if not executed from root" - thanks to [gardar](https://github.com/gardar)

## [2.0.0](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/tree/2.0.0) - released at 20220207

### Added in 2.0.0

* added support to run an existing iso
* added usage of pacman-init.service including check of expected content
* added output if iso building is not successful

### Changed in 2.0.0

* major rework of internal code - adapted to archiso changes
  * all code is now running into dedicated functions
* aligned output
* moveing the existing iso to $somewhere
* fixed issue with not enough access when generating the checksum files

## [1.3.0](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/tree/1.3.0) - released at 20160823

### Changed in 1.3.0

* implemented user input to select fitting archzfs-linux repository

## [1.2.0](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/tree/1.2.0) - released at 20160706

### Added in 1.2.0

* added automatically renaming each created iso file to archlinux.iso
* added automatically md5sum and sha1sum file creation of created archlinux.iso

## [1.1.0](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/tree/1.1.0) - released at 20160514

### Added in 1.1.0

* added [README.md](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/blob/master/README.md)

### Changed in 1.1.0

* renamed "build" directory to "dynamic_data" to ease up execution of "build.sh"

## [1.0.0](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/tree/1.0.0) - released at 20160512

### Added in 1.0.0

* initial commit
