#!/usr/bin/env bash

yum update -y
yum install -y mdadm smartmontools hdparm gdisk
yum install -y nano wget

# Уничтожаем структуры данных GPT и MBR
sgdisk --zap-all /dev/sdb

# Очищаем таблицу разделов
sgdisk -o /dev/sdb

# Создание GPT-раздела и 5 партиций
sgdisk -n 1:0:+1M --typecode=1:EF02 /dev/sdb
sgdisk -n 2:0:+512M --typecode=2:8300 /dev/sdb
sgdisk -n 3:0:+256M --typecode=3:8300 /dev/sdb
sgdisk -n 4:0:+512M --typecode=4:8300 /dev/sdb
sgdisk -n 5:0:+128M --typecode=5:8300 /dev/sdb
sgdisk --largest-new=6 /dev/sdb

# Копируем таблицу разделов с /dev/sdb на /dev/sdc
sgdisk -R /dev/sdc /dev/sdb

# делаем уникальными скопированные GUID разделов
sgdisk -G /dev/sdc

# Перемещаем второй заголовок в конец диска
sgdisk --randomize-guids --move-second-header /dev/sdc

# Создаем RAID 0
mdadm --create --verbose /dev/md0 --force --level=0 --raid-devices=2 /dev/sdb2 /dev/sdc2
mdadm --create --verbose /dev/md1 --force --level=0 --raid-devices=2 /dev/sdb4 /dev/sdc4

# Создаем RAID 1
# mdadm --create --verbose /dev/md2 --force --level=1 --raid-devices=2 /dev/sdb3 /dev/sdc3
# mdadm --create --verbose /dev/md3 --force --level=1 --raid-devices=2 /dev/sdb5 /dev/sdc5
# mdadm --create --verbose /dev/md4 --force --level=1 --raid-devices=2 /dev/sdb6 /dev/sdc6

# mdadm --detail --scan --verbose
# df -h -x devtmpfs -x tmpfs

#
# mkdir /mnt/md{0,1,5,6,10}
# mkfs.ext4 /dev/md0
# mkfs.ext4 /dev/md1
# mount /dev/md0 /mnt/md0
# mount /dev/md1 /mnt/md1
