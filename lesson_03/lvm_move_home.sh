#!/usr/bin/env bash

STAGE_LOG=/home/vagrant/stage.log

VG='VolGroup00'
LV='lv_home'
SIZE='2G'

#Автозапуск данного сценария после перезагрузки системы
function make_service {
   local SERVICE_FILE='/etc/systemd/system/lvm_move_home.service'
   touch $SERVICE_FILE
   chmod 664 $SERVICE_FILE

cat > $SERVICE_FILE <<'_EOF_'
[Unit]
Description=Migrating home to a separate volume
After=network.target
[Service]
Type=oneshot
User=root
ExecStart=/home/vagrant/lvm_move_home.sh
[Install]
WantedBy=multi-user.target
_EOF_

   systemctl enable lvm_move_home.service
}

function lvm_create_new_home {
    lvcreate -n $LV -L $SIZE /dev/$VG
    mkfs.xfs /dev/$VG/$LV
}

function lvm_move_to_new_home {
    mount /dev/$VG/$LV /mnt/
    cp -aR /home/* /mnt/
    rm -rf /home/*
    umount /mnt
    mount /dev/$VG/$LV /home/
    echo "`blkid | grep home | awk '{print $2}'` /home xfs defaults 0 0" \
        >> /etc/fstab
}


STAGE=`cat $STAGE_LOG |grep move_home | cut -d "=" -f 2`
case $STAGE in
    0)  sed -i 's/move_home=.*/move_home=1/' $STAGE_LOG
        make_service
        lvm_create_new_home
        lvm_move_to_new_home
        reboot
        ;;

    1)  systemctl disable lvm_move_home.service
        sed -i 's/move_home=.*/move_home=2/' $STAGE_LOG
        ;;

    2)  echo "Раздел home перенесен на отдельный том. Все операции завершены"
        ;;

    *)  echo "Ошибка в файле $STAGE_LOG"
        exit 1
        ;;
esac
