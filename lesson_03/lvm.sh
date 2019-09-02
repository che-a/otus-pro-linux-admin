#!/usr/bin/env bash

REPORT_LOG=report_lvm.log   # Файл, в который будет логироваться ход выполнения всех заданий
STAGE_LOG=/home/vagrant/stage.log         # Файл, в который записывается уровенеь проведенных изменений, чтобы после перезагрузки системы не начинать все сначала

NEW_SIZE=8G           # Новый размер тома, ГБ

PV='/dev/sda3'
VG='VolGroup00'
LV='LogVol00'

TMP_PV='/dev/sdb'           # Временный физческий том
TMP_VG='VGTMP'               #
TMP_LV='lv_tmp'        #

NEW_LV='lv_reduce_root'

STAGE=

# Логирование вывода информационных команд с целью отслеживания изменений
# по ходу выполнения задания
function report {
    local CMDS=('lsblk' \
                'df -h -x tmpfs -x devtmpfs' \
                'pvs' \
                'vgs' \
                'lvs' )

    for i in $(seq 1 80); do echo -n "#" >> $REPORT_LOG; done
    (echo ; echo "#### $1:") >> $REPORT_LOG
    for i in $(seq 1 80); do echo -n "#" >> $REPORT_LOG; done
    echo >> $REPORT_LOG

    for i in "${CMDS[@]}"; do
        (echo ========== $i ==========; sh -c "$i") >> $REPORT_LOG;
    done
}

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

function lv_create_new_home {
    lvcreate -n LogVol_Home -L 2G /dev/VolGroup00
    mkfs.xfs /dev/VolGroup00/LogVol_Home
    mount /dev/VolGroup00/LogVol_Home /mnt/
    cp -aR /home/* /mnt/
    rm -rf /home/*
    umount /mnt
    mount /dev/VolGroup00/LogVol_Home /home/
    echo "`blkid | grep Home | awk '{print $2}'` /home xfs defaults 0 0" \
        >> /etc/fstab
}


if [ ! -f $STAGE_LOG ]; then
   echo "Выполнять нечего (файл '$STAGE_LOG' не существует)."
   exit 1
else
    STAGE=`cat $STAGE_LOG`
    case $STAGE in
        0)  report "Исходная система"
            echo "1" > $STAGE_LOG
            lvm_create_tmp_root
            lvm_move_to_tmp_root
            lvm_reconfig_grub2 $VG $LV $TMP_VG $TMP_LV
            reboot
            ;;

        1)  report "Система с корнем на временном томе"
            echo "2" > $STAGE_LOG
            lvm_create_new_root
            lvm_move_to_new_root
            lvm_reconfig_grub2 $VG $LV $VG $NEW_LV
            reboot
            ;;

        2)  report "Система с уменьшенным корневым томом с ФС XFS"
            echo "3" > $STAGE_LOG
            lvm_del_tmp_root
            lvm_create_new_var
            lvm_move_to_new_var
            lv_create_new_home
            ;;

        3)  echo "Текущий уровень 3"
            ;;

        *)  echo "Ошибка в файле $STAGE_LOG"
            exit 1
            ;;
    esac
fi
