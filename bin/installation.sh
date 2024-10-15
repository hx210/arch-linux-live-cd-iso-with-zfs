#!/bin/bash
####
# Automated installation of zfs for your arch linux
# I am not the smart guy inventing this. I am just someone glueing things togehter.
####
# @todo
#   Move question into seperate configuration
# @see
#  https://github.com/eoli3n/archiso-zfs
#  https://github.com/eoli3n/arch-config
#  https://github.com/picodotdev/alis
#  https://github.com/MatMoul/archfi/blob/master/archfi
#  https://get.zfsbootmenu.org/
# @since 20220625T19:25:20
# @author stev leibelt <artodeto@bazzline.net>
####

#bo: configuration
function _run_configuration ()
{
    local DEVICE_PATH
    local HOSTNAME_PATH
    local LANGUAGE_PATH
    local LOCAL_PATH
    local TIMEZONE_PATH
    local USERNAME_PATH
    local ZPOOLDATASET_PATH
    local ZPOOLNAME_PATH

    DEVICE_PATH="${PATH_TO_THE_CONFIGURATION_DIRECTORY}/device"
    HOSTNAME_PATH="${PATH_TO_THE_CONFIGURATION_DIRECTORY}/hostname"
    LANGUAGE_PATH="${PATH_TO_THE_CONFIGURATION_DIRECTORY}/language"
    LOCAL_PATH="${PATH_TO_THE_CONFIGURATION_DIRECTORY}/local"
    TIMEZONE_PATH="${PATH_TO_THE_CONFIGURATION_DIRECTORY}/timezone"
    USERNAME_PATH="${PATH_TO_THE_CONFIGURATION_DIRECTORY}/username"
    ZPOOLDATASET_PATH="${PATH_TO_THE_CONFIGURATION_DIRECTORY}/zpooldataset"
    ZPOOLNAME_PATH="${PATH_TO_THE_CONFIGURATION_DIRECTORY}/zpoolname"

    mkdir "${PATH_TO_THE_CONFIGURATION_DIRECTORY}"

    mkdir "${PATH_TO_THE_CONFIGURATION_DIRECTORY}"

    _ask "Please input your prefered language (default is >>de<<)"
    if [[ ${#REPLY} -ne 2 ]];
    then
        REPLY="de"
    fi
    echo "${REPLY}" > "${LANGUAGE_PATH}"

    _ask "Please insert locales (default is >>de_DE.UTF-8<<)"
    if [[ ${#REPLY} -ne 11 ]];
    then
        REPLY="de_DE.UTF-8"
    fi
    echo "${REPLY}" > "${LOCAL_PATH}"

    _ask "Please input your prefered timezone (default is >>Europe/Berlin<<)"
    if [[ ${#REPLY} -eq 0 ]];
    then
        REPLY="Europe/Berlin"
    fi
    echo "${REPLY}" > "${TIMEZONE_PATH}"

    _ask "Please insert your username: "
    echo "${REPLY}" > "${USERNAME_PATH}"

    #ask user what device he want to use, remove all entries with "-part" to prevent listing partitions
    echo ":: Please select a device where we want to install it."

    select USER_SELECTED_ENTRY in $(ls /dev/disk/by-id/ | grep -v "\-part");
    do
        USER_SELECTED_DEVICE="/dev/disk/by-id/${USER_SELECTED_ENTRY}"
        #store the selection
        echo "${USER_SELECTED_DEVICE}" > "${DEVICE_PATH}"
        break
    done

    _ask "Do you want to add a four character random string to the end of >>zpool<<? (y|N) "

    local ZPOOL_NAME

    ZPOOL_NAME="rpool"

    if echo ${REPLY} | grep -iq '^y$';
    then
        local RANDOM_STRING

        RANDOM_STRING=$(echo ${RANDOM} | md5sum | head -c 4)

        ZPOOL_NAME="${ZPOOL_NAME}-${RANDOM_STRING}"
    fi
    echo "${ZPOOL_NAME}" > "${ZPOOLNAME_PATH}"

    _ask "Name of the root dataset below >>${ZPOOL_NAME}/ROOT<< (default is tank)? "

    local ZPOOL_DATASET

    ZPOOL_DATASET="${ZPOOL_NAME}/ROOT/${REPLY:-tank}"

    echo "${ZPOOL_DATASET}" > "${ZPOOLDATASET_PATH}"

    _ask "Please insert hostname: "
    echo "${REPLY}" > "${HOSTNAME_PATH}"
}

####
# @param <string: configuration name>
#   device
#   hostname
#   language
#   timezone
#   username
#   zpooldataset
#   zpoolname
####
function _get_from_configuration ()
{
    local CONFIGURATION_FILE_PATH

    case ${1} in
        "device")
            CONFIGURATION_FILE_PATH="${PATH_TO_THE_CONFIGURATION_DIRECTORY}/device"
            ;;
        "hostname")
            CONFIGURATION_FILE_PATH="${PATH_TO_THE_CONFIGURATION_DIRECTORY}/hostname"
            ;;
        "language")
            CONFIGURATION_FILE_PATH="${PATH_TO_THE_CONFIGURATION_DIRECTORY}/language"
            ;;
        "local")
            CONFIGURATION_FILE_PATH="${PATH_TO_THE_CONFIGURATION_DIRECTORY}/local"
            ;;
        "timezone")
            CONFIGURATION_FILE_PATH="${PATH_TO_THE_CONFIGURATION_DIRECTORY}/timezone"
            ;;
        "username")
            CONFIGURATION_FILE_PATH="${PATH_TO_THE_CONFIGURATION_DIRECTORY}/username"
            ;;
        "zpooldataset")
            CONFIGURATION_FILE_PATH="${PATH_TO_THE_CONFIGURATION_DIRECTORY}/zpooldataset"
            ;;
        "zpoolname")
            CONFIGURATION_FILE_PATH="${PATH_TO_THE_CONFIGURATION_DIRECTORY}/zpoolname"
            ;;
        *)
            CONFIGURATION_FILE_PATH=${RANDOM}
            ;;
    esac

    if [[ -f ${CONFIGURATION_FILE_PATH} ]];
    then
        cat "${CONFIGURATION_FILE_PATH}"
    else
        echo ":: Invalid configuration section >>${1}<< selected."

        ext 1
    fi
}
#eo: configuration

#bo: preparation
function _prepare_environment ()
{
    local LANGUAGE
    local TIMEZONE

    if grep -q "arch.*iso" /proc/cmdline;
    then
        _echo_if_be_verbose ":: This is an arch.*iso."
    else
        echo ":: Looks like we are not in an >>arch*.iso<< environment."

        exit 1
    fi

    if [[ -d /sys/firmware/efi/efivars ]];
    then
        _echo_if_be_verbose ":: UEFI is available."
    else
        echo ":: Looks like there is no uefi available."
        echo "   Sad thing, uefi is required."

        exit 2
    fi

    if ping archlinux.org -c 1 >/dev/null;
    then
        _echo_if_be_verbose ":: We are online."
    else
        echo ":: Looks like we are offline."
        echo "   Could not ping >>archlinux.org<<."

        exit 3
    fi

    if lsmod | grep -q zfs;
    then
        _echo_if_be_verbose ":: Module zfs is loaded."
    else
        echo ":: Looks like zfs module is not loaded."

        exit 4
    fi

    LANGUAGE=$(_get_from_configuration "language")
    _echo_if_be_verbose "   Loading keyboad >>${LANGUAGE}<<."
    loadkeys "${LANGUAGE}"

    #bo: time
    TIMEZONE=$(_get_from_configuration "timezone")
    _echo_if_be_verbose "   Setting timezone >>${TIMEZONE}<<."
    timedatectl set-timezone ${REPLY}

    timedatectl set-ntp true
    #eo: time

    _echo_if_be_verbose ":: Increasing cowspace to half of the RAM."

    #usefull to install more
    mount -o remount,size=50% /run/archiso/cowspace
}

function _initialize_archzfs ()
{
    if pacman -Sl archzfs >/dev/null 2>&1;
    then
        _echo_if_be_verbose ":: Archzfs repository already added."

        return
    fi

    _echo_if_be_verbose ":: Adding archzfs to the repository."
    _confirm_every_step

    #adding key
    pacman -Syy archlinux-keyring --noconfirm &>/dev/null
    pacman-key --populate archlinux &>/dev/null
    pacman-key -r DDF7DB817396A49B2A2723F7403BD972F75D9D76
    pacman-key --lsign-key DDF7DB817396A49B2A2723F7403BD972F75D9D76

    #creating mirrorlist
    cat >> /etc/pacman.d/archzfs <<"DELIM"
Server = http://archzfs.com/archzfs/x86_64
Server = http://mirror.sum7.eu/archlinux/archzfs/archzfs/x86_64
Server = https://mirror.biocrafting.net/archlinux/archzfs/archzfs/x86_64
DELIM

    #adding repository
    cat >> /etc/pacman.conf <<"DELIM"
[archzfs]
Include = /etc/pacman.d/archzfs
DELIM

    #updating packages
    pacman -Sy &>/dev/null

    #@see https://github.com/eoli3n/archiso-zfs/blob/master/init#L46
    #maybe add a flag like >>--archive-version="2022/02/01"<<
}
#eo: preparation

#bo: configuration
function _setup_zfs_passphrase ()
{
    read -r -p "> Please insert your zfs passphrase: " -s USER_INPUT_PASSPHRASE
    echo "" #needed since read does not output \n

    echo "${USER_INPUT_PASSPHRASE}" > /etc/zfs/zroot.key
    chmod 000 /etc/zfs/zroot.key
}

function _wipe_device ()
{
    local DEVICE_PATH

    DEVICE_PATH=$(_get_from_configuration "device")

    _ask "Do you want to wipe the device >>${DEVICE_PATH}<<? (y|N)"

    if echo ${REPLY} | grep -iq '^y$';
    then
        _echo_if_be_verbose ":: dd >>${DEVICE_PATH}<<.."
        dd if=/dev/zero of="${DEVICE_PATH}" bs=512 count=1

        _echo_if_be_verbose ":: wipefs >>${DEVICE_PATH}<<."
        wipefs -af "${DEVICE_PATH}"

        _echo_if_be_verbose ":: sgdisk >>${DEVICE_PATH}<<."
        sgdisk -Zo "${DEVICE_PATH}"
    else
        echo ":: No wipe, no progress."
        echo "   Will exit now."

        exit 0
    fi
}

function _partition_device ()
{
    local DEVICE_PATH=
    local EFI_PARTITION

    DEVICE_PATH=$(_get_from_configuration "device")

    _echo_if_be_verbose ":: Creating EFI partition."
    sgdisk -n1:1M:+512M -t1:EF00 "${DEVICE_PATH}"
    EFI_PARTITION="${DEVICE_PATH}-part1"
    
    _echo_if_be_verbose ":: Creating ZFS partition."
    sgdisk -n3:0:0 -t3:bf01 "${DEVICE_PATH}"

    _echo_if_be_verbose ":: Informing kernel about partition changes."
    partprobe "${DEVICE_PATH}"

    _echo_if_be_verbose ":: Formating EFI partition."
    sleep 1 #needed to fix a possible issue that partprobe is not done yet
    mkfs.vfat "${EFI_PARTITION}"
}

function _setup_zpool_and_dataset ()
{
    local EFI_PARTITION
    local DEVICE_PATH
    local ZFS_PARTITION
    local ZPOOL_NAME
    local ZPOOL_DATASET

    DEVICE_PATH=$(_get_from_configuration "device")
    ZPOOL_NAME=$(_get_from_configuration "zpoolname")
    ZPOOL_DATASET=$(_get_from_configuration "zpooldataset")

    local EFI_PARTITION="${DEVICE_PATH}-part1"
    local ZFS_PARTITION="${DEVICE_PATH}-part3"

    _echo_if_be_verbose ":: Using device partition >>${ZFS_PARTITION}<<"
    _echo_if_be_verbose "   Creating zfs pool on device path >>${ZFS_PARTITION}<<."

    if [[ ! -h "${EFI_PARTITION}" ]];
    then
        echo ":: Expected device link >>${EFI_PARTITION}<< does not exist."

        exit 1
    fi

    if [[ ! -h "${ZFS_PARTITION}" ]];
    then
        echo ":: Expected device link >>${ZFS_PARTITION}<< does not exist."

        exit 2
    fi

    if [[ ! -f /etc/zfs/zroot.key ]];
    then
        echo ":: Expected file >>/etc/zfs/zroot.key<< does not exist."

        exit 3
    fi

    zpool create -f -o ashift=12                          \
                 -o autotrim=on                           \
                 -O acltype=posixacl                      \
                 -O compression=zstd                      \
                 -O relatime=on                           \
                 -O xattr=sa                              \
                 -O dnodesize=legacy                      \
                 -O encryption=aes-256-gcm                \
                 -O keyformat=passphrase                  \
                 -O keylocation=file:///etc/zfs/zroot.key \
                 -O normalization=formD                   \
                 -O mountpoint=none                       \
                 -O canmount=off                          \
                 -O devices=off                           \
                 -R /mnt                                  \
                 "${ZPOOL_NAME}" "${ZFS_PARTITION}"

    _confirm_every_step

    #bo: create pool
    _echo_if_be_verbose ":: Creating root dataset"
    zfs create -o mountpoint=none "${ZPOOL_NAME}/ROOT"

    _echo_if_be_verbose ":: Set the commandline"
    zfs set org.zfsbootmenu:commandline="ro quiet" "${ZPOOL_NAME}/ROOT"
    #eo: create pool

    #bo: create system dataset
    _echo_if_be_verbose ":: Creating root dataset >>${ZPOOL_DATASET}<<"
    zfs create -o mountpoint=/ -o canmount=noauto "${ZPOOL_DATASET}"

    _echo_if_be_verbose ":: Creating zfs hostid"
    zgenhostid

    _echo_if_be_verbose ":: Configuring bootfs"
    zpool set bootfs="${ZPOOL_DATASET}" "${ZPOOL_NAME}"

    _echo_if_be_verbose ":: Manually mounting dataset"
    zfs mount "${ZPOOL_DATASET}"
    _confirm_every_step
    #eo: create system dataset

    #bo: create home dataset
    _echo_if_be_verbose ":: Creating home dataset"
    zfs create -o mountpoint=/ -o canmount=off "${ZPOOL_NAME}/data"
    zfs create                                 "${ZPOOL_NAME}/data/home"
    _confirm_every_step
    #eo: create home dataset

    #bo: pool reload
    _echo_if_be_verbose ":: Export pool"
    zpool export "${ZPOOL_NAME}"

    _echo_if_be_verbose ":: Import pool"
    zpool import -d /dev/disk/by-id -R /mnt "${ZPOOL_NAME}" -N -f
    zfs load-key "${ZPOOL_NAME}"
    _confirm_every_step
    #eo: pool reload

    #bo: mount system
    _echo_if_be_verbose ":: Mounting system dataset"
    zfs mount "${ZPOOL_DATASET}"
    ##mounting the rest
    zfs mount -a

    _echo_if_be_verbose ":: Mounting EFI partition >>${EFI_PARTITION}<<"
    mkdir -p /mnt/efi
    mount "${EFI_PARTITION}" /mnt/efi
    _confirm_every_step
    #eo: mount system

    #bo: copy zfs cache
    _echo_if_be_verbose ":: Copy zpool cache"
    mkdir -p /mnt/etc/zfs
    zpool set cachefile=/etc/zfs/zpool.cache "${ZPOOL_NAME}"
    _confirm_every_step
    #eo: copy zfs cache
}
#eo: configuration

#bo: general
####
# @param <string: ask message>
####
function _ask ()
{
    read -p ">> ${1}: " -r
    echo
}

function _confirm_every_step ()
{
    if [[ ${CONFIRM_EVERY_STEP} -eq 1 ]];
    then
        read -p "Press enter to continue"
    fi
}

####
# @param <string: message>
####
function _echo_if_be_verbose ()
{
    if [[ ${BE_VERBOSE} -gt 0 ]];
    then
        echo "${1}" 
    fi
}

function _main ()
{
    #bo: variables
    local AVAILABLE_STEPS
    local BE_VERBOSE
    local CURRENT_RUNNING_KERNEL_VERSION
    local CURRENT_STEP
    local CURRENT_WORKING_DIRECTORY
    local CONFIRM_EVERY_STEP
    local IS_DRY_RUN
    local PATH_TO_THE_CONFIGURATION_DIRECTORY
    local PATH_TO_THIS_SCRIPT
    local SELECTED_STEP
    local SHOW_HELP
    local ZPOOL_NAME

    AVAILABLE_STEPS=8
    CURRENT_WORKING_DIRECTORY=$(pwd)
    PATH_TO_THE_CONFIGURATION_DIRECTORY="/tmp/_configuration"
    PATH_TO_THIS_SCRIPT=$(cd "$(dirname "${0}")" || exit; pwd)
    CURRENT_RUNNING_KERNEL_VERSION=$(uname -r)
    #eo: variables

    #bo: user input
    BE_VERBOSE=0
    SELECTED_STEP=0
    CONFIRM_EVERY_STEP=0
    IS_DRY_RUN=0
    SHOW_HELP=0

    while true;
    do
        case "${1}" in
            "-d" | "--dry-run" )
                IS_DRY_RUN=1
                ;;
            "-c" | "--confirm" )
                CONFIRM_EVERY_STEP=1
                shift 1
                ;;
            "-h" | "--help" )
                SHOW_HELP=1
                shift 1
                ;;
            "-s" | "--step" )
                SELECTED_STEP="${2}"
                shift 2
                ;;
            "-v" | "--verbose" )
                set +x
		        exec &> >(tee "debug.log")
		        echo ":: >>debug.log<< is filled with data"
                BE_VERBOSE=1
                shift 1
                ;;
            * )
                break
                ;;
        esac
    done
    #eo: user input

    #bo: verbose output
    if [[ ${BE_VERBOSE} -eq 1 ]];
    then
        echo ":: Dumping variables"
        echo "   BE_VERBOSE: >>${BE_VERBOSE}<<."
        echo "   CONFIRM_EVERY_STEP: >>${CONFIRM_EVERY_STEP}<<."
        echo "   CURRENT_RUNNING_KERNEL_VERSION: >>${CURRENT_RUNNING_KERNEL_VERSION}<<."
        echo "   CURRENT_WORKING_DIRECTORY: >>${CURRENT_WORKING_DIRECTORY}<<."
        echo "   IS_DRY_RUN: >>${IS_DRY_RUN}<<."
        echo "   PATH_TO_THIS_SCRIPT: >>${PATH_TO_THIS_SCRIPT}<<."
        echo "   PROJECT_ROOT_PATH: >>${PROJECT_ROOT_PATH}<<."
        echo "   SELECTED_STEP: >>${SELECTED_STEP}<< from >>${AVAILABLE_STEPS}<<."
        echo ""
    fi
    #eo: verbose output

    #bo: help
    if [[ ${SHOW_HELP} -eq 1 ]];
    then
        echo ":: Usage"
        echo "   ${0} [-c|--confirm] [-d|--dry-run] [-h|--help] [-s|--step <int: 1-${AVAILABLE_STEPS}>] [-v|--verbose]"

        exit 0
    fi
    #eo: help

    #bo: configuration
    if [[ ! -d "${PATH_TO_THE_CONFIGURATION_DIRECTORY}" ]];
    then
        _run_configuration
    fi
    #eo: configuration

    #bo: preparation
    CURRENT_STEP=1

    if [[ ${SELECTED_STEP} -eq 0 ]] || [[ ${SELECTED_STEP} -eq ${CURRENT_STEP} ]];
    then
        _echo_if_be_verbose ":: bo step ${CURRENT_STEP} - preperation"

        _prepare_environment
        _confirm_every_step

        _initialize_archzfs
        _confirm_every_step

        _echo_if_be_verbose ":: eo step ${CURRENT_STEP} - preperation"
    fi

    #@see https://github.com/eoli3n/archiso-zfs/blob/master/init#L157
    #I guess we don't need it since we are running an archzfs
    #eo: preparation

    #bo: configuration
    CURRENT_STEP=2

    if [[ ${SELECTED_STEP} -eq 0 ]] || [[ ${SELECTED_STEP} -eq ${CURRENT_STEP} ]];
    then
        _echo_if_be_verbose ":: bo step ${CURRENT_STEP} - device setup"

        _select_device
        _setup_zfs_passphrase
        _confirm_every_step

        _wipe_device
        _partition_device
        _setup_zpool_and_dataset
        _confirm_every_step

        _echo_if_be_verbose ":: Sorting mirrors"
        systemctl start reflector

        _echo_if_be_verbose ":: eo step ${CURRENT_STEP} - device setup"
    fi
    #eo: configuration

    #bo: installation
    CURRENT_STEP=3

    if [[ ${SELECTED_STEP} -eq 0 ]] || [[ ${SELECTED_STEP} -eq ${CURRENT_STEP} ]];
    then
        _echo_if_be_verbose ":: bo step${CURRENT_STEP}  - Install base system"
        #@todo: ask for a list or let the user provide a list of tools
        pacstrap /mnt       \
            base            \
            base-devel      \
            linux           \
            linux-headers   \
            linux-firmware  \
            efibootmgr      \
            vim             \
            git             \
            networkmanager

        _confirm_every_step

    ZPOOL_NAME=$(_get_from_configuration "zpoolname")

        _echo_if_be_verbose "   Generate fstab excluding zfs entries"
        genfstab -U /mnt | grep -v "${ZPOOL_NAME}" | tr -s '\n' | sed 's/\/mnt//'  > /mnt/etc/fstab

        _echo_if_be_verbose ":: eo step${CURRENT_STEP}  - Install base system"
    fi

    CURRENT_STEP=4

    if [[ ${SELECTED_STEP} -eq 0 ]] || [[ ${SELECTED_STEP} -eq ${CURRENT_STEP} ]];
    then
        _echo_if_be_verbose ":: bo step ${CURRENT_STEP} - Configure base system"

        local USER_INPUT_LANGUAGE
        local USER_INPUT_LOCAL
        local USER_INPUT_TIMEZONE
        local USER_HOSTNAME

        USER_INPUT_LANGUAGE=$(_get_from_configuration "language")
        USER_INPUT_LOCAL=$(_get_from_configuration "local")
        USER_INPUT_TIMEZONE=$(_get_from_configuration "timezone")
        USER_HOSTNAME=$(_get_from_configuration "hostname")

        echo "${USER_HOSTNAME}" > /mnt/etc/hostname

        _echo_if_be_verbose ":: Configuring /etc/hosts"

        cat > /mnt/etc/hosts <<DELIM
#<ip-address>	<hostname.domain.org>	<hostname>
127.0.0.1	    localhost   	        ${USER_HOSTNAME}
::1   		    localhost              	${USER_HOSTNAME}
DELIM

        echo "KEYMAP=${USER_INPUT_LANGUAGE}" > /mnt/etc/vconsole.conf
        sed -i "s/#\(${USER_INPUT_LOCAL}\)/\1/" /mnt/etc/locale.gen
        echo "LANG=\"${USER_INPUT_LOCAL}\"" > /mnt/etc/locale.conf

        _echo_if_be_verbose ":: eo step ${CURRENT_STEP} - Configure base system"

        _confirm_every_step
    fi

    CURRENT_STEP=5

    if [[ ${SELECTED_STEP} -eq 0 ]] || [[ ${SELECTED_STEP} -eq ${CURRENT_STEP} ]];
    then
        _echo_if_be_verbose ":: bo step ${CURRENT_STEP} - Setup zfs"
        local USER_NAME

        USER_NAME=$(_get_from_configuration "username")

        _echo_if_be_verbose "   Preparing initramfs"
        cat > /mnt/etc/mkinitcpio.conf <<DELIM
MODULES=()
BINARIES=()
FILES=(/etc/zfs/zroot.key)
HOOKS=(base udev autodetect modconf block keyboard keymap zfs filesystems)
COMPRESSION="zstd"
DELIM
        _confirm_every_step

        _echo_if_be_verbose "   Copying zfs files"
        cp /etc/hostid /mnt/etc/hostid
        cp /etc/zfs/zpool.cache /mnt/etc/zfs/zpool.cache
        cp /etc/zfs/zroot.key /mnt/etc/zfs

        _confirm_every_step

        _echo_if_be_verbose "   Chroot and configure system"
        arch-chroot /mnt /bin/bash -xe <<DELIM
### Reinit keyring
# As keyring is initialized at boot, and copied to the install dir with pacstrap, and ntp is running
# Time changed after keyring initialization, it leads to malfunction
# Keyring needs to be reinitialised properly to be able to sign archzfs key.

rm -Rf /etc/pacman.d/gnupg
pacman-key --init
pacman-key --populate archlinux
pacman-key -r DDF7DB817396A49B2A2723F7403BD972F75D9D76
pacman-key --lsign-key DDF7DB817396A49B2A2723F7403BD972F75D9D76
pacman -S archlinux-keyring --noconfirm

cat >> /etc/pacman.d/archzfs <<"EOSF"
Server = http://archzfs.com/archzfs/x86_64
Server = http://mirror.sum7.eu/archlinux/archzfs/archzfs/x86_64
Server = https://mirror.biocrafting.net/archlinux/archzfs/archzfs/x86_64
EOSF

cat >> /etc/pacman.conf <<"EOSF"
[archzfs]
Include = /etc/pacman.d/archzfs
EOSF
  pacman -Syu --noconfirm zfs-utils

  #synchronize clock
  hwclock --systohc

  #set date
  timedatectl set-ntp true

  #@todo: fetch from previous
  timedatectl set-timezone ${USER_INPUT_TIMEZONE}

  #generate locale
  locale-gen
  source /etc/locale.conf

  #generate initramfs
  mkinitcpio -P

  #install zfsbootmenu and dependencies
  #maybe use a prebuild instead?
  #@see: https://get.zfsbootmenu.org/

  #bo: from the arch wiki
  #@see: https://wiki.archlinux.org/title/Install_Arch_Linux_on_ZFS#Using_ZFSBootMenu_for_UEFI
  # /boot must be on the root filesystem
  # mount your esp
  #
  ##bo: generate image
  # pacman -S zfsbootmenu (aur) and efibootmgr
  # configure /etc/zfsbootmenu/config.yaml
  # generate zfsbootmenu image
  #   generate-zbm
  # configure zfs boot commandline arguments
  #   zfs set org.zfsbootmenu:commandline="rw" zroot/ROOT
  # add zfsbootmenu entry to efi boot manager
  #   # efibootmgr -c -d your_esp_disk -p your_esp_partition_number -L "ZFSBootMenu" -l '\EFI\zbm\vmlinuz-linux.EFI'
  ##eo: generate image
  ##bo: use binary
  # pacman -S zfsbootmenu-efi-bin (aur) and efibootmgr
  # configure zfs boot commandline arguments
  #   zfs set org.zfsbootmenu:commandline="rw" zroot/ROOT
  # add zfsbootmenu entry to efi boot manager
  #   # efibootmgr -c -d your_esp_disk -p your_esp_partition_number -L "ZFSBootMenu" -l '\EFI\zbm\zfsbootmenu-release-vmlinuz-x86_64.EFI'
  ##eo: use binary
  #eo: from the arch wiki

  git clone --depth=1 https://github.com/zbm-dev/zfsbootmenu/ /tmp/zfsbootmenu
  pacman -S cpanminus kexec-tools fzf util-linux --noconfirm
  cd /tmp/zfsbootmenu
  make
  make install
  cpanm --notest --installdeps .

  #create user
  useradd -m ${USER_NAME}
DELIM
        _confirm_every_step

        echo "   Setting password of >>root<<"
        arch-chroot /mnt /bin/passwd

        echo "   Setting password of >>${USER_NAME}<<"
        arch-chroot /mnt /bin/passwd "${USER_NAME}"

        _confirm_every_step

        _echo_if_be_verbose "   Configuring sudo"
        cat > /mnt/etc/sudoers <<DELIM
root ALL=(ALL) ALL
${USER_NAME} ALL=(ALL) ALL
Defaults rootpw
DELIM

        _echo_if_be_verbose ":: eo step ${CURRENT_STEP} - Setup zfs"
    fi

    CURRENT_STEP=6

    if [[ ${SELECTED_STEP} -eq 0 ]] || [[ ${SELECTED_STEP} -eq ${CURRENT_STEP} ]];
    then
        _echo_if_be_verbose ":: eo step ${CURRENT_STEP} - Configure zfs"

        #@todo configure network
        #   https://github.com/eoli3n/arch-config/blob/master/scripts/zfs/install/02-install.sh#L160
        #@todo configure dns
        #   https://github.com/eoli3n/arch-config/blob/master/scripts/zfs/install/02-install.sh#L196

        _echo_if_be_verbose "   Configuring zfs"
        systemctl enable zfs-import-cache --root=/mnt
        systemctl enable zfs-mount --root=/mnt
        systemctl enable zfs-import.target --root=/mnt
        systemctl enable zfs.target --root=/mnt

        _confirm_every_step

        _echo_if_be_verbose "   Configure zfs-mount-generator"
        mkdir -p /mnt/etc/zfs/zfs-list.cache
        touch /mnt/etc/zfs/zfs-list.cache/${ZPOOL_NAME}
        zfs list -H -o name,mountpoint,canmount,atime,relatime,devices,exec,readonly,setuid,nbmand | sed 's/\/mnt//' > /mnt/etc/zfs/zfs-list.cache/${ZPOOL_NAME}
        systemctl enable zfs-zed.service --root=/mnt

        _confirm_every_step

        _echo_if_be_verbose ":: eo step ${CURRENT_STEP} - Configure zfs"
    fi

    CURRENT_STEP=7

    if [[ ${SELECTED_STEP} -eq 0 ]] || [[ ${SELECTED_STEP} -eq ${CURRENT_STEP} ]];
    then
        _echo_if_be_verbose ":: bo step ${CURRENT_STEP} - Configure and setup zfsbootmenu"

        _echo_if_be_verbose "   Configure zfsbootmenu"
        mkdir -p /mnt/efi/EFI/ZBM

        _echo_if_be_verbose "   Generate zfsbootmenu efi"
        #@see https://github.com/zbm-dev/zfsbootmenu/blob/master/etc/zfsbootmenu/mkinitcpio.conf
        cat > /mnt/etc/zfsbootmenu/mkinitcpio.conf <<DELIM
MODULES=()
BINARIES=()
FILES=()
HOOKS=(base udev autodetect modconf block keyboard keymap)
COMPRESSION="zstd"
EOF

cat > /mnt/etc/zfsbootmenu/config.yaml <<EOF
Global:
  ManageImages: true
  BootMountPoint: /efi
  InitCPIO: true
Components:
  Enabled: false
EFI:
  ImageDir: /efi/EFI/ZBM
  Versions: false
  Enabled: true
Kernel:
  CommandLine: ro quiet loglevel=0 zbm.import_policy=hostid
  Prefix: vmlinuz
DELIM

        _echo_if_be_verbose "   Setting commandline"
        zfs set org.zfsbootmenu:commandline="rw quiet nowatchdog rd.vconsole.keymap=${USER_INPUT_LANGUAGE}" "${ZPOOL_ROOT_DATASET}"
        _confirm_every_step

        local DEVICE_PATH

        DEVICE_PATH=$(_get_from_configuration "device")

        _echo_if_be_verbose "   Configuring zfsbootmenu language"
        arch-chroot /mnt /bin/bash -xe <<DELIM
# Export locale
export LANG="${USER_INPUT_LOCAL}"
# Generate zfsbootmenu
generate-zbm
DELIM

        _confirm_every_step

        _echo_if_be_verbose "   Creating UEFI entries"
        local USER_SELECTED_DEVICE

        USER_SELECTED_DEVICE=$(cat /tmp/_selected_device)
        
        if ! efibootmgr | grep ZFSBootMenu
        then
            efibootmgr --disk "${USER_SELECTED_DEVICE}" \
              --part 1 \
              --create \
              --label "ZFSBootMenu Backup" \
              --loader "\EFI\ZBM\vmlinuz-backup.efi" \
              --verbose
            efibootmgr --disk "${USER_SELECTED_DEVICE}" \
              --part 1 \
              --create \
              --label "ZFSBootMenu" \
              --loader "\EFI\ZBM\vmlinuz.efi" \
              --verbose
        else
            _echo_if_be_verbose "   Boot entries already created"
        fi

        _echo_if_be_verbose ":: eo step ${CURRENT_STEP} - Configure and setup zfsbootmenu"
    fi

    CURRENT_STEP=8

    if [[ ${SELECTED_STEP} -eq 0 ]] || [[ ${SELECTED_STEP} -eq ${CURRENT_STEP} ]];
    then
        _echo_if_be_verbose ":: bo step ${CURRENT_STEP} - tear down"

        _echo_if_be_verbose "   Unmounting all partitions"
        umount /mnt/efi
        zfs umount -a

        _echo_if_be_verbose "   Exporting zpool"
        zpool export "${ZPOOL_NAME}"

        _echo_if_be_verbose ":: bo step ${CURRENT_STEP} - tear down"
    fi
    #eo: installation

    echo ":: Done"
    #cd "${CURRENT_WORKING_DIRECTORY}"
}
#eo: general

_main "${@}"
