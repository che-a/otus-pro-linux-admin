#!/usr/bin/env bash

STAGE_LOG=/home/vagrant/stage.log

PV1='/dev/sdc'
PV2='/dev/sdd'
VG='VG01'
LV='lv_var'
SIZE=950M

#Автозапуск данного сценария после перезагрузки системы
function make_service {
   local SERVICE_FILE='/etc/systemd/system/lvm_move_var.service'
   touch $SERVICE_FILE
   chmod 664 $SERVICE_FILE

cat > $SERVICE_FILE <<'_EOF_'
[Unit]
Description=Migrating var to a separate volume
After=network.target

[Service]
Type=oneshot
User=root
ExecStart=/home/vagrant/lvm_move_var.sh

[Install]
WantedBy=multi-user.target
_EOF_

   systemctl enable lvm_move_var.service
}

function lvm_create_new_var {
    pvcreate $PV1 $PV2
    vgcreate $VG $PV1 $PV2
    lvcreate -L 950M -m1 -n $LV $VG
    mkfs.ext4 /dev/$VG/$LV
}

function lvm_move_to_new_var {
    mount /dev/$VG/$LV /mnt
    cp -aR /var/* /mnt/
    rm -rf /var/*
    umount /mnt
    mount /dev/$VG/$LV /var
    echo "`blkid | grep var: | awk '{print $2}'` /var ext4 defaults 0 0" \
        >> /etc/fstab
}


STAGE=`cat $STAGE_LOG |grep move_var | cut -d "=" -f 2`
case $STAGE in
    0)  sed -i 's/move_var=.*/move_var=1/' $STAGE_LOG
        make_service
        lvm_create_new_var
        lvm_move_to_new_var
        reboot
        ;;

    1)  systemctl disable lvm_move_var.service
        sed -i 's/move_var=.*/move_var=2/' $STAGE_LOG
        ;;

    2)  echo "Раздел var перенесен на отдельный том. Все операции завершены"
        ;;

    *)  echo "Ошибка в файле $STAGE_LOG"
        exit 1
        ;;
esac
