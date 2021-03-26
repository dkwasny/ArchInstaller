#!/bin/bash

# Additional tasks to get the Arch running in VMWare

echo "Installing VMWare packages.";
pacman -S \
	xf86-video-vmware \
	xf86-input-vmmouse \
	open-vm-tools;

echo "Enabling VMWare services.";
systemctl enable vmtoolsd;
#systemctl enable vmware-vmblock-fuse;

# See https://bbs.archlinux.org/viewtopic.php?id=223470
echo "Fixing VM scroll behavior";
echo "GDK_CORE_DEVICE_EVENTS=1" >> /etc/environment;
