#!/usr/bin/env bash

STAGE_LOG_FILE='stage.log'
STAGE_LOG_PATH='/home/vagrant/'$STAGE_LOG_FILE

CENTOS_MINOR_VER=`cat /etc/redhat-release | cut -d" " -f 4 | cut -d"." -f 2`
ZFS_PATH="http://download.zfsonlinux.org/epel"
ZFS_PACKAGE="$ZFS_PATH/zfs-release.el7_$CENTOS_MINOR_VER.noarch.rpm"


STAGE=`cat $STAGE_LOG_PATH |grep lvm_reduce_move | cut -d "=" -f 2`
case $STAGE in
    0)  yum install -y update
        yum install -y $ZFS_PACKAGE
        yum install -y kernel-devel zfs
        sed -i 's/zfs=.*/zfs=1/' $STAGE_LOG_PATH
        reboot
        ;;

    1)  sed -i 's/zfs=.*/zfs=2/' $STAGE_LOG_PATH
        ;;

    2)  sed -i 's/zfs=.*/zfs=3/' $STAGE_LOG_PATH
        ;;

    3)  echo "Все операции завершены."
        ;;

    *)  echo "Ошибка в файле $STAGE_LOG"
        exit 1
        ;;
esac
