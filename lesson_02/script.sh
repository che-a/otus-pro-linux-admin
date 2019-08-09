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

# Создание RAID 0
mdadm --create --verbose /dev/md0 --force --level=0 --raid-devices=2 /dev/sdb2 /dev/sdc2
mdadm --create --verbose /dev/md1 --force --level=0 --raid-devices=2 /dev/sdb4 /dev/sdc4

# Создание RAID 1
mdadm --create --metadata=1.2 --verbose /dev/md2 --force --level=1 --raid-devices=2 /dev/sdb3 /dev/sdc3
mdadm --create --metadata=1.2 --verbose /dev/md3 --force --level=1 --raid-devices=2 /dev/sdb5 /dev/sdc5
mdadm --create --metadata=1.2 --verbose /dev/md4 --force --level=1 --raid-devices=2 /dev/sdb6 /dev/sdc6

# Создание RAID 5
mdadm --create --verbose /dev/md5 --level=5 --raid-devices=4 /dev/sd{d,e,f,g}

# Удаление RAID 5
sleep 10
mdadm --stop /dev/md5
mdadm --zero-superblock /dev/sdd
mdadm --zero-superblock /dev/sde
mdadm --zero-superblock /dev/sdf
mdadm --zero-superblock /dev/sdg

# Создание RAID 6
mdadm --create --verbose /dev/md6 --level=6 --raid-devices=4 /dev/sd{d,e,f,g}

# Удаление RAID 6
sleep 10
mdadm --stop /dev/md6
mdadm --zero-superblock /dev/sdd
mdadm --zero-superblock /dev/sde
mdadm --zero-superblock /dev/sdf
mdadm --zero-superblock /dev/sdg

# Создание RAID 10
mdadm --create --verbose /dev/md10 --level=10 --raid-devices=4 /dev/sd{d,e,f,g}


# Создание файла конфигурации mdadm.conf
echo "DEVICE partitions" > /etc/mdadm.conf
mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm.conf

# shutdown -r now
# df -h -x devtmpfs -x tmpfs

#
# mkdir /mnt/md{0,1,5,6,10}
# mkfs.ext4 /dev/md0
# mkfs.ext4 /dev/md1
# mount /dev/md0 /mnt/md0
# mount /dev/md1 /mnt/md1
