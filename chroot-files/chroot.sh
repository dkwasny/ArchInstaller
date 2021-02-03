#!/bin/bash

# Script that contains all commands that need to be run after chrooting
# to the new root filesystem.

# Fail on any command error
set -ex;

function usage() {
    echo "Usage: $0 -n <hostname> -u <username> -t <network-device>";
    exit 0;
}

function check-var() {
    if [ -z "$1" ]; then
        echo "$2 not set";
        usage;
    fi;
}

while getopts "n:u:t:h" ARG; do
    case "$ARG" in
        n) HOSTNAME="$OPTARG";;
        u) USERNAME="$OPTARG";;
        t) NETWORK_DEVICE="$OPTARG";;
        h) usage;;
        *) usage;;
    esac;
done;

check-var "$HOSTNAME" "Hostname";
check-var "$USERNAME" "Username";
check-var "$NETWORK_DEVICE" "NetworkDevice";

echo "Setting up timezone.";
ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime;

echo "Setting up locale.";
LOCALE_STRING="en_US.UTF-8";
sed -i"" "s/#$LOCALE_STRING/$LOCALE_STRING/g" /etc/locale.gen;
locale-gen;
echo "LANG=$LOCALE_STRING" > /etc/locale.conf;

echo "Setting hostname.";
echo "$HOSTNAME" > /etc/hostname;

echo "Creating hosts file";
mv /chroot-files/hosts /etc/hosts;
sed -i"" "s/HOSTNAME/$HOSTNAME/g" /etc/hosts;

echo "Setting up network config file";
mv /chroot-files/20-wired.network /etc/systemd/network/20-wired.network;
sed -i"" "s/NETWORK_DEVICE/$NETWORK_DEVICE/g" /etc/systemd/network/20-wired.network;

echo "Setting root's password.";
echo "root:password" | chpasswd;

echo "Creating user: $USERNAME.";
useradd -m "$USERNAME";
echo "$USERNAME:password" | chpasswd;
mkdir -m 700 /etc/sudoers.d;
echo "$USERNAME ALL=(ALL) ALL" > /etc/sudoers.d/"$USERNAME";

echo "Installing packages.";
pacman -S $(cat /chroot-files/packages | grep -v '^#');

echo "Setting up GRUB.";
grub-install \
    --target=x86_64-efi \
    --efi-directory=/boot \
    --bootloader-id=arch-grub;
grub-mkconfig -o /boot/grub/grub.cfg;

echo "Enabling Systemd Services.";
systemctl enable $(cat /chroot-files/services | grep -v '^#');

read -p "Perform additional VMWare guest setup? (y/n): " CONFIRM;
if [ "$CONFIRM" == "y" ]; then
    echo "Performing VMWare setup.";
    /chroot-files/vmware.sh;
fi;
