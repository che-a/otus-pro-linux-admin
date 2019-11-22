#!/usr/bin/env bash

VG_OLD=`vgdisplay | grep "VG Name" | gawk '{print $3}'`
VG_NEW='CheLes07Root'


vgrename $VG_OLD $VG_NEW

sed -i "s/$VG_OLD/$VG_NEW/g" /etc/fstab
sed -i "s/$VG_OLD/$VG_NEW/g" /boot/grub2/grub.cfg

dracut -f -v

echo "Reboot virtual machine ..."
reboot
