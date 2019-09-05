#!/usr/bin/env bash

SERVICE_FILE='zfs_otus.service'
SERVICE_PATH='/etc/systemd/system/'$SERVICE_FILE

STAGE_FILE='stage.log'
STAGE_PATH='/home/vagrant/'$STAGE_FILE

# Автозапуск данного сценария после перезагрузки системы
function make_systemd_service {
    touch $SERVICE_PATH
    chmod 664 $SERVICE_PATH

cat > $SERVICE_PATH <<'_EOF_'
[Unit]
Description=Using ZFS
After=network.target
[Service]
Type=oneshot
User=root
ExecStart=/home/vagrant/zfs.sh
[Install]
WantedBy=multi-user.target
_EOF_

    systemctl enable $SERVICE_FILE
}


STAGE=`cat $STAGE_PATH |grep zfs | cut -d "=" -f 2`
case $STAGE in
    0)  make_systemd_service
        yum update -y
        sed -i 's/zfs=.*/zfs=1/' $STAGE_PATH
        reboot
        ;;

    1)  # В CentOS 7 по умолчанию не поддержки ZFS
        CENTOS7_MINOR_VER=`cat /etc/redhat-release | cut -d" " -f 4 | cut -d"." -f 2`
        ZFS_REPO_PATH="http://download.zfsonlinux.org/epel"
        ZFS_REPO="$ZFS_REPO_PATH/zfs-release.el7_$CENTOS7_MINOR_VER.noarch.rpm"
        yum install -y $ZFS_REPO
        # Включение kABI-tracking kmod
        sed -i '0,/enabled=0/{s/enabled=0/enabled=1/}' /etc/yum.repos.d/zfs.repo
        sed -i '0,/enabled=1/{s/enabled=1/enabled=0/}' /etc/yum.repos.d/zfs.repo
        yum install -y zfs

        zpool create otus_pool /dev/sdb /dev/sdc -f -m none
        zpool add otus_pool cache /dev/sdd
        zpool add otus_pool log /dev/sde
        zfs create otus_pool/opt
        zfs set mountpoint=/opt otus_pool/opt

        # Делаем снимок состояния
        echo "Version 1" > /opt/test.txt
        zfs snapshot otus_pool/opt@version1

        systemctl disable $SERVICE_FILE
        sed -i 's/zfs=.*/zfs=2/' $STAGE_PATH
        # Перзагрузка для проверки работоспособности системы
        reboot
        ;;

    2)  echo "Все операции с ZFS завершены."
        ;;

    *)  echo "Ошибка в файле $STAGE_FILE"
        exit 1
        ;;
esac
