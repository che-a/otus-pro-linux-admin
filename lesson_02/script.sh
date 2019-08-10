#!/usr/bin/env bash

# RAID 0 и 1 создаются на разделах дисков /dev/sdb и /dev/sdc
# RAID 5, 6 и 10 создаются на дисках /dev/sd{d,e,f,g}


# Подготовка системы: обновление и установка необходимых пакетов
function prepare_system {
    yum update -y
    yum install -y mdadm smartmontools hdparm gdisk
    yum install -y nano wget tree

    # Директории для монтирования RAID и RAID-разделов
    mkdir /mnt/md{{0..4},10,{5,6,10}p{1..6}}
}

# Подготовка дисков /dev/sdb и /dev/sdc к сборке RAID 0 и RAID 1
# - удаление структур данных GPT и MBR
# - удаление таблицы разделов
# - создание GPT-раздела и 5 партиций
function prepare_raid_0_1 {
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

    return
}

# Создание RAID 0
function create_raid0 {
    mdadm --create --verbose $1 --force --level=0 --raid-devices=2 $2 $3
}

# Создание RAID 1
function create_raid1 {
    mdadm --create --metadata=1.2 --verbose $1 --force --level=1 --raid-devices=2 $2 $3
}

# Создание RAID 5
function create_raid5 {
    mdadm --create --verbose $1 --level=5 --raid-devices=4 /dev/sd{d,e,f,g}
}

# Создание RAID 6
function create_raid6 {
    mdadm --create --verbose $1 --level=6 --raid-devices=4 /dev/sd{d,e,f,g}
}

# Создание RAID10
function create_raid10 {
    mdadm --create --verbose $1 --level=10 --raid-devices=4 /dev/sd{d,e,f,g}
}

# Удаление RAID 5,6,10
function destroy_raid {
    sleep 10
    mdadm --stop $1
    mdadm --zero-superblock /dev/sdd
    mdadm --zero-superblock /dev/sde
    mdadm --zero-superblock /dev/sdf
    mdadm --zero-superblock /dev/sdg
}

# Создание GPT-раздела и 5 партиций на RAID 5,6,10
function part_raid {

    # Уничтожаем структуры данных GPT и MBR
    sgdisk --zap-all /dev/sdd
    sgdisk --zap-all /dev/sde
    sgdisk --zap-all /dev/sdf
    sgdisk --zap-all /dev/sdg

    # Очищаем таблицу разделов
    sgdisk -o /dev/sdd
    sgdisk -o /dev/sde
    sgdisk -o /dev/sdf
    sgdisk -o /dev/sdg

    sgdisk -n 1:0:+1M --typecode=1:EF02 $1
    sgdisk -n 2:0:+16M --typecode=2:8300 $1
    sgdisk -n 3:0:+24M --typecode=3:8300 $1
    sgdisk -n 4:0:+32M --typecode=4:8300 $1
    sgdisk -n 5:0:+48M --typecode=5:8300 $1
    sgdisk --largest-new=6 $1
}

function mount_raid_part {

    return
}

function mkfs_mount {
    # Монтирование
    mkfs.ext4 /dev/md0
    mkfs.ext4 /dev/md1
    mkfs.ext4 /dev/md2
    mkfs.ext4 /dev/md3
    mkfs.ext4 /dev/md4
    mount /dev/md0 /mnt/md0
    mount /dev/md1 /mnt/md1
    mount /dev/md2 /mnt/md2
    mount /dev/md3 /mnt/md3
    mount /dev/md4 /mnt/md4

    return
}

function build_mdadm_conf {
    # Создание файла конфигурации mdadm.conf
    echo "DEVICE partitions" > /etc/mdadm.conf
    mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm.conf
}


prepare_system

prepare_raid_0_1
create_raid0 "/dev/md0" "/dev/sdb2" "/dev/sdc2"
create_raid0 "/dev/md1" "/dev/sdb4" "/dev/sdc4"
create_raid1 "/dev/md2" "/dev/sdb3" "/dev/sdc3"
create_raid1 "/dev/md3" "/dev/sdb5" "/dev/sdc5"
create_raid1 "/dev/md4" "/dev/sdb6" "/dev/sdc6"

create_raid5 "/dev/md5"
part_raid "/dev/md5"
destroy_raid "/dev/md5"

create_raid6 "/dev/md6"
part_raid "/dev/md6"
destroy_raid "/dev/md6"

create_raid10 "/dev/md10"
part_raid "/dev/md10"

build_mdadm_conf
