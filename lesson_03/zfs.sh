#!/usr/bin/env bash

# В CentOS 7 по умолчанию нет поддержки ZFS
CENTOS7_MINOR_VER=`cat /etc/redhat-release | cut -d" " -f 4 | cut -d"." -f 2`
ZFS_REPO_PATH="http://download.zfsonlinux.org/epel"
ZFS_REPO="$ZFS_REPO_PATH/zfs-release.el7_$CENTOS7_MINOR_VER.noarch.rpm"
yum install -y $ZFS_REPO
# Включение kABI-tracking kmod
sed -i '0,/enabled=0/{s/enabled=0/enabled=1/}' /etc/yum.repos.d/zfs.repo
sed -i '0,/enabled=1/{s/enabled=1/enabled=0/}' /etc/yum.repos.d/zfs.repo
yum install -y zfs

echo zfs >> /etc/modules-load.d/zfs.conf # добавляем модуль zfs в автозапуск
modprobe zfs # запускаем модуль zfs чтоб не перезагружаться

zpool create otus_pool /dev/sdb /dev/sdc -f -m none
zpool add otus_pool cache /dev/sdd
zpool add otus_pool log /dev/sde
zfs create otus_pool/opt
zfs set mountpoint=/opt otus_pool/opt

# Делаем снимок состояния
echo "Version 1" > /opt/test.txt
zfs snapshot otus_pool/opt@version1
