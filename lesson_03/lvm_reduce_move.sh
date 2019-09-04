#!/usr/bin/env bash

SERVICE_FILE='lvm_reduce_move.service'
SERVICE_PATH='/etc/systemd/system/'$SERVICE_FILE

STAGE_LOG_FILE='stage.log'
STAGE_LOG_PATH='/home/vagrant/'$STAGE_LOG_FILE

PV1_VAR='/dev/sdc'
PV2_VAR='/dev/sdd'

VG_ROOT='VolGroup00'
VG_VAR='VG01'
LV_HOME='lv_home'
LV_ROOT='LogVol00'
LV_VAR='lv_var'

TMP_PV_ROOT='/dev/sdb'
TMP_VG_ROOT='VGTMP'
TMP_LV_ROOT='lv_tmp'

NEW_SIZE_HOME='2G'
NEW_SIZE_ROOT='8G'
NEW_SIZE_VAR='950M'

# Автозапуск данного сценария после перезагрузки системы
function make_systemd_service {
    touch $SERVICE_PATH
    chmod 664 $SERVICE_PATH

cat > $SERVICE_PATH <<'_EOF_'
[Unit]
Description=Reduce XFS root volume, move home and var
After=network.target
[Service]
Type=oneshot
User=root
ExecStart=/home/vagrant/lvm_reduce_move.sh
[Install]
WantedBy=multi-user.target
_EOF_

    systemctl enable $SERVICE_FILE
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
    sed -i "s+root=/dev/mapper/$1-$2+root=/dev/mapper/$3-$4+" /boot/grub2/grub.cfg
    sed -i "s+rd.lvm.lv=$1/$2+rd.lvm.lv=$3/$4+" /boot/grub2/grub.cfg
}


STAGE=`cat $STAGE_LOG_PATH |grep lvm_reduce_move | cut -d "=" -f 2`
case $STAGE in
    0)  make_systemd_service

        # Создание временного тома с XFS для корня
        pvcreate $TMP_PV_ROOT
        vgcreate $TMP_VG_ROOT $TMP_PV_ROOT
        lvcreate -n $TMP_LV_ROOT -l +100%FREE /dev/$TMP_VG_ROOT
        mkfs.xfs /dev/$TMP_VG_ROOT/$TMP_LV_ROOT

        # Номер следующего этапа
        sed -i 's/lvm_reduce_move=.*/lvm_reduce_move=1/' $STAGE_LOG_PATH

        # Перенос файлов корня на временный том
        mount /dev/$TMP_VG_ROOT/$TMP_LV_ROOT /mnt
        xfsdump -J - /dev/$VG_ROOT/$LV_ROOT | xfsrestore -J - /mnt

        # Переконфигурирование Grub2 с целью последующего запуска
        # системы с временным корнем
        lvm_reconfig_grub2 $VG_ROOT $LV_ROOT $TMP_VG_ROOT $TMP_LV_ROOT

        # Перезагрузка для запуска системы с примонтированным времененным корнем
        reboot
        ;;

    1)  sed -i 's/lvm_reduce_move=.*/lvm_reduce_move=2/' $STAGE_LOG_PATH

        # Удаление старого корневого тома
        lvremove /dev/$VG_ROOT/$LV_ROOT --force

        # Создание нового уменьшенного тома для корня
        lvcreate -y -n $LV_ROOT -L $NEW_SIZE_ROOT /dev/$VG_ROOT
        mkfs.xfs /dev/$VG_ROOT/$LV_ROOT
        # Создание нового тома для переноса в него /var
        pvcreate $PV1_VAR $PV2_VAR
        vgcreate $VG_VAR $PV1_VAR $PV2_VAR
        lvcreate -L $NEW_SIZE_VAR -m1 -n $LV_VAR $VG_VAR
        mkfs.ext4 /dev/$VG_VAR/$LV_VAR
        # Создание нового тома для переноса в него /home
        lvcreate -n $LV_HOME -L $NEW_SIZE_HOME /dev/$VG_ROOT
        mkfs.xfs /dev/$VG_ROOT/$LV_HOME

        # Монтирование нового /var после загрузки системы
        echo "`blkid | grep $LV_VAR:|awk '{print $2}'` /var ext4 defaults 0 0"\
            >> /etc/fstab
        echo "`blkid | grep $LV_HOME|awk '{print $2}'` /home xfs defaults 0 0" \
            >> /etc/fstab

        # Копирование всех файлов с временного корня на новый
        mkdir /mnt/new_root
        mount /dev/$VG_ROOT/$LV_ROOT /mnt/new_root
        xfsdump -J - /dev/$TMP_VG_ROOT/$TMP_LV_ROOT | xfsrestore -J - /mnt/new_root

        # Переконфигурирование Grub2 с целью последующего запуска
        # системы с временным корнем
        lvm_reconfig_grub2 $TMP_VG_ROOT $TMP_LV_ROOT $VG_ROOT $LV_ROOT

        # Перенос с временного тома директории /var в новый том для /var
        mkdir /mnt/new_var
        mount /dev/$VG_VAR/$LV_VAR /mnt/new_var
        cp -aR /mnt/new_root/var/* /mnt/new_var/
        rm -rf /mnt/new_root/var/*
        umount /mnt/new_var

        # Перенос с временного тома директории /home в новый том для /home
        mkdir /mnt/new_home
        mount /dev/$VG_ROOT/$LV_HOME /mnt/new_home
        cp -aR /mnt/new_root/home/* /mnt/new_home
        rm -rf /mnt/new_root/home/*
        umount /mnt/new_home

        # Перезагрузка для запуска системы с уменьшенным корнем и
        # отдельными томами для /home и /var
        reboot
        ;;

    2)  sed -i 's/lvm_reduce_move=.*/lvm_reduce_move=3/' $STAGE_LOG_PATH

        lvremove /dev/$TMP_VG_ROOT/$TMP_LV_ROOT --force
        vgremove /dev/$TMP_VG_ROOT
        pvremove $TMP_PV_ROOT

        systemctl disable lvm_reduce_move.service
        ;;

    3)  echo "Все операции завершены."
        ;;

    *)  echo "Ошибка в файле $STAGE_LOG"
        exit 1
        ;;
esac
