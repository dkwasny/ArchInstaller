#!/bin/bash

# Additional tasks to get the Arch running in VMWare

echo "Installing VMWare packages."
pacman -S xf86-video-vmware open-vm-tools;

echo "Enabling VMWare services."
systemctl enable vmware-vmblock-fuse;