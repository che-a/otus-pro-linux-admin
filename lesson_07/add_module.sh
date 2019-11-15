#!/usr/bin/env bash

mkdir /usr/lib/dracut/modules.d/01test
cp /vagrant/{module-setup,test}.sh /usr/lib/dracut/modules.d/01test
dracut -f -v

sed -i "s/rhgb/ /" /boot/grub2/grub.cfg
sed -i "s/quiet/ /" /boot/grub2/grub.cfg

reboot
