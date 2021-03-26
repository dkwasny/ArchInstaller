#!/bin/bash

# Additional tasks to get the Arch running in VMWare

# Add the following lines to the VMX file to make scrolling not feel like hot garbage.
# Auto mouse (un)capture is lost, and the cursor is laggy, but its better than broken scrolling.
#
# mks.gamingMouse.policy = "gaming"
# mouse.vusb.useBasicMouse=FALSE

echo "Installing VMWare packages.";
pacman -S \
	xf86-video-vmware \
	xf86-input-vmmouse \
	open-vm-tools;

echo "Enabling VMWare services.";
systemctl enable vmtoolsd;
#systemctl enable vmware-vmblock-fuse;
