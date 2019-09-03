#!/usr/bin/env bash

NEW_SIZE=8G

VG='VolGroup00'
LV='LogVol00'

TMP_PV='/dev/sdb'
TMP_VG='VGTMP'
TMP_LV='lv_tmp'

# Создание временного тома для корня и копирование в него данных из текущего
function lvm_create_tmp_root {
    pvcreate $TMP_PV
    vgcreate $TMP_VG $TMP_PV
    lvcreate -n $TMP_LV -l +100%FREE /dev/$TMP_VG
    mkfs.xfs /dev/$TMP_VG/$TMP_LV
}

function lvm_move_to_tmp_root {
    mount /dev/$TMP_VG/$TMP_LV /mnt
    xfsdump -J - /dev/$VG/$LV | xfsrestore -J - /mnt
}

function lvm_reconfig_grub2 {
    for i in /proc/ /sys/ /dev/ /run/ /boot/; do
        mount --bind $i /mnt/$i;
    done
chroot /mnt/ /bin/bash <<'EOT'
grub2-mkconfig -o /boot/grub2/grub.cfg
# Обновление образа initrd
cd /boot;
for i in `ls initramfs-*img`; do
    dracut -v $i `echo $i|sed "s/initramfs-//g;s/.img//g"` --force;
done
EOT
    sed -i "s+rd.lvm.lv=$1/$2+rd.lvm.lv=$3/$4+" \
        /boot/grub2/grub.cfg
}

# Удаление старого корневого тома и создание нового
function lvm_create_new_root {
    lvremove /dev/$VG/$LV --force
    lvcreate -y -n $NEW_LV -L $NEW_SIZE /dev/$VG
    mkfs.xfs /dev/$VG/$NEW_LV
}

function lvm_move_to_new_root {
    mount /dev/$VG/$NEW_LV /mnt
    xfsdump -J - /dev/$TMP_VG/$TMP_LV | xfsrestore -J - /mnt
}

function lvm_del_tmp_root {
    lvremove /dev/$TMP_VG/$TMP_LV --force
    vgremove /dev/$TMP_VG
    pvremove $TMP_PV
}
