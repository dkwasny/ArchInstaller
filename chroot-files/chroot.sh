#!/bin/bash

# Script that contains all commands that need to be run after chrooting
# to the new root filesystem.

# Fail on any command error
set -e;

function usage() {
    echo "Usage: $0 -n <hostname> -u <username>";
    exit 0;
}

function check-var() {
    if [ -z "$1" ]; then
        echo "$2 not set";
        usage;
    fi;
}

while getopts "n:u:h" ARG; do
    case "$ARG" in
        n) HOSTNAME="$OPTARG";;
        u) USERNAME="$OPTARG";;
        h) usage;;
        *) usage;;
    esac;
done;

check-var "$HOSTNAME" "Hostname";
check-var "$USERNAME" "Username";

echo "Setting up timezone.";
ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime;

echo "Turning on NTP time syncing.";
timedatectl set-ntp true;

echo "Setting up locale.";
LOCALE_STRING="en_US.UTF-8 UTF-8";
sed -i"" "s/#$LOCALE_STRING/$LOCALE_STRING/g" /etc/locale.gen;

echo "Setting hostname.";
echo "$HOSTNAME" > /etc/hostname;

echo "Setting root's password.";
echo "root:password" | chpasswd;

echo "Creating user: $USERNAME.";
useradd -m "$USERNAME";
echo "$USERNAME:password" | chpasswd;
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

# Run VMWare setup. Remove this after I move to a real system.
echo "Performing VMWare setup."
/chroot-files/vmware.sh
