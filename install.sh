#!/bin/bash

# Perform a simple Arch installation per the wiki guide.

function usage() {
    echo "Usage: $0 -d <device> -n <hostname> -u <username>";
    exit 0;
}

function confirm() {
    read -p "$1" CONFIRM;
    if [ "$CONFIRM" != "y" ]; then
        echo "Aborting installation...";
        exit 0;
    fi;
}

function check-var() {
    if [ -z "$1" ]; then
        echo "$2 not set";
        usage;
    fi;
}

while getopts "d:n:u:h" ARG; do
    case "$ARG" in
        d) DEVICE="$OPTARG";;
        n) HOSTNAME="$OPTARG";;
        u) USERNAME="$OPTARG";;
        h) usage;;
        *) usage;;
    esac;
done;

check-var "$DEVICE" "Device";
check-var "$HOSTNAME" "Hostname";
check-var "$USERNAME" "Username";

echo "Ensuring $DEVICE does not have live mounts."
if mount | grep "$DEVICE"; then
    echo "$DEVICE appears to have live mounts.";
    echo "Aborting installation...";
    exit 1;
fi;

echo "Ensuring root mount point exists.";
ROOT_MOUNT="/mnt/root";
if [ -a "$ROOT_MOUNT" ]; then
    echo "$ROOT_MOUNT already exists.";
    confirm "Attempt to unmount and delete (y/n): ";
    umount "$ROOT_MOUNT";
    rm -rf "$ROOT_MOUNT";
fi;

echo "Creating mount point.";
mkdir "$ROOT_MOUNT";

echo "Creating partitions on $DEVICE.";
echo "This will clear everything on the device.";
confirm "Are you sure (y/n): ";

# The actual installation starts here.  Fail when any following step fails.
set -ex;

# Turn off all swap devices on the off chance the device has a mounted
# swap partition.
echo "Turning off all swap devices.";
swapoff -a;

echo "Creating new partition table.";
sgdisk -o "$DEVICE";

PARTITION_NUM=1;
echo "Creating boot partition.";
BOOT_PARTITION="$DEVICE$PARTITION_NUM";
sgdisk \
    -n "$PARTITION_NUM:0:+512M" "$DEVICE" \
    -c "$PARTITION_NUM:BOOT" "$DEVICE" \
    -t "$PARTITION_NUM:ef00" "$DEVICE";

((PARTITION_NUM++));
echo "Creating swap partition.";
SWAP_PARTITION="$DEVICE$PARTITION_NUM";
sgdisk \
    -n "$PARTITION_NUM:0:+2G" "$DEVICE" \
    -c "$PARTITION_NUM:SWAP" "$DEVICE" \
    -t "$PARTITION_NUM:8200" "$DEVICE";

((PARTITION_NUM++));
echo "Creating root partition.";
ROOT_PARTITION="$DEVICE$PARTITION_NUM";
sgdisk \
    -n "$PARTITION_NUM:0:0" "$DEVICE" \
    -c "$PARTITION_NUM:ROOT" "$DEVICE" \
    -t "$PARTITION_NUM:8300" "$DEVICE";

echo "Informing kernel of new partitions.";
partprobe "$DEVICE";

echo "Creating filesystems.";
mkfs.vfat -n BOOT -F 32 "$BOOT_PARTITION";
mkswap -L SWAP "$SWAP_PARTITION";
swapon "$SWAP_PARTITION";
mkfs.ext4 -L ROOT "$ROOT_PARTITION";

echo "Mounting partitions.";
BOOT_MOUNT="$ROOT_MOUNT/boot";
mount "$ROOT_PARTITION" "$ROOT_MOUNT";
mkdir "$BOOT_MOUNT";
mount "$BOOT_PARTITION" "$BOOT_MOUNT";

echo "Performing base install (pacstrap).";
pacstrap "$ROOT_MOUNT" base linux linux-firmware;

echo "Generating fstab.";
genfstab -U "$ROOT_MOUNT" >> "$ROOT_MOUNT/etc/fstab";

echo "Copying chroot-files to $ROOT_MOUNT.";
cp -r chroot-files "$ROOT_MOUNT";

echo "Chrooting to $ROOT_MOUNT.";
arch-chroot "$ROOT_MOUNT" /chroot-files/chroot.sh \
    -n "$HOSTNAME" \
    -u "$USERNAME";

echo "Removing copy of chroot-files.";
rm -r "$ROOT_MOUNT/chroot-files";

echo "Installation Complete!";
echo "REMEMBER TO SET THE ROOT AND USER PASSWORDS TO REAL VALUES!";
echo "Restart when ready."
