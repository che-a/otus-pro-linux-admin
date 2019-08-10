#!/usr/bin/env bash

# RAID 0 и 1 создаются на разделах дисков /dev/sdb и /dev/sdc
# RAID 5, 6 и 10 создаются на дисках /dev/sd{d,e,f,g}

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

function create_raid0 {
    echo "START CREATING RAID 0 $1 ON DEVICES $2 AND $3"
    mdadm --create --verbose $1 --force --level=0 --raid-devices=2 $2 $3
}

function create_raid1 {
    echo "START CREATING RAID 1 $1 ON DEVICES $2 AND $3"
    mdadm --create --metadata=1.2 --verbose $1 --force --level=1 --raid-devices=2 $2 $3
}

# Создание RAID 5/6/10
function create_raid {
    local MD=
    local MD_DISKS="/dev/sd{d,e,f,g}"
    case $1 in
        5)  echo "Создание RAID 5"
            MD="/dev/md5"
            mdadm --create --verbose $MD --level=5 --raid-devices=4 $MD_DISKS

            mkdir /mnt/md5p{1..6}
            ;;

        6)  echo "RAID 6"
            MD="/dev/md6"
            mdadm --create --verbose /dev/md6 --level=6 --raid-devices=4 /dev/sd{d,e,f,g}

            mkdir /mnt/md6p{1..6}
            ;;

        10) echo "RAID 10"
            MD="/dev/md10"
            mdadm --create --verbose /dev/md10 --level=10 --raid-devices=4 /dev/sd{d,e,f,g}

            mkdir /mnt/md10p{1..6}
            ;;

        *)  echo "Invalid RAID level" >&2
            exit 1
            ;;
    esac

    parted -s $MD mklabel gpt

    parted $MD mkpart primary ext4 0% 20%
    parted $MD mkpart primary ext4 20% 40%
    parted $MD mkpart primary ext4 40% 60%
    parted $MD mkpart primary ext4 60% 80%
    parted $MD mkpart primary ext4 80% 100%

}

# Подготовка системы: обновление и установка необходимых пакетов
yum update -y
yum install -y mdadm smartmontools hdparm gdisk
yum install -y nano wget tree

prepare_raid_0_1
create_raid0 "/dev/md0" "/dev/sdb2" "/dev/sdc2"
create_raid0 "/dev/md1" "/dev/sdb4" "/dev/sdc4"
create_raid1 "/dev/md2" "/dev/sdb3" "/dev/sdc3"
create_raid1 "/dev/md3" "/dev/sdb5" "/dev/sdc5"
create_raid1 "/dev/md4" "/dev/sdb6" "/dev/sdc6"

create_raid 5

# Создание файла конфигурации mdadm.conf
echo "DEVICE partitions" > /etc/mdadm.conf
mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm.conf
