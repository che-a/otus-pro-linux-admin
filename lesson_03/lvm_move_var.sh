#!/usr/bin/env bash

function lvm_create_new_var {
    pvcreate /dev/sdc /dev/sdd
    vgcreate VG01 /dev/sdc /dev/sdd
    lvcreate -L 950M -m1 -n lv_var VG01
    mkfs.ext4 /dev/VG01/lv_var
}

function lvm_move_to_new_var {
    mount /dev/VG01/lv_var /mnt
    cp -aR /var/* /mnt/
    mkdir /tmp/oldvar && mv /var/* /tmp/oldvar
    umount /mnt
    mount /dev/VG01/lv_var /var
    echo "`blkid | grep var: | awk '{print $2}'` /var ext4 defaults 0 0" \
        >> /etc/fstab
}
