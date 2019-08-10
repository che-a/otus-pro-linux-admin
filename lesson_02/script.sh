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

# Создание RAID 1/5/6/10
function create_raid {
    case $1 in
        1)  echo "Creating RAID 1"
            mdadm --create --verbose --metadata=1.2 /dev/md$1 --force --level=1 --raid-devices=2 /dev/sd{d,e}
            mdadm /dev/md$1 --add /dev/sdf
            mdadm /dev/md$1 --add /dev/sdg
            ;;
        5)  echo "Creating RAID 5"
            mdadm --create --verbose /dev/md$1 --level=5 --raid-devices=4 /dev/sd{d,e,f,g}
            ;;
        6)  echo "Creating RAID 6"
            mdadm --create --verbose /dev/md$1 --level=6 --raid-devices=4 /dev/sd{d,e,f,g}
            ;;
        10) echo "Creating RAID 10"
            mdadm --create --verbose /dev/md$1 --level=10 --raid-devices=4 /dev/sd{d,e,f,g}
            ;;
        *)  echo "Invalid RAID level!" >&2
            exit 1
            ;;
    esac

    parted -s /dev/md$1 mklabel gpt

    parted /dev/md$1 mkpart primary ext4 0% 20%
    parted /dev/md$1 mkpart primary ext4 20% 40%
    parted /dev/md$1 mkpart primary ext4 40% 60%
    parted /dev/md$1 mkpart primary ext4 60% 80%
    parted /dev/md$1 mkpart primary ext4 80% 100%

    for i in $(seq 1 5); do
        mkdir -p /mnt/raid/md$1p$i
        mkfs.ext4 /dev/md$1p$i;
        mount /dev/md$1p$i /mnt/raid/md$1p$i;
    done

}

# yum update -y
yum install -y mdadm smartmontools hdparm gdisk
yum install -y nano wget tree

#prepare_raid_0_1
#create_raid0 "/dev/md20" "/dev/sdb2" "/dev/sdc2"
#create_raid0 "/dev/md21" "/dev/sdb4" "/dev/sdc4"
#create_raid1 "/dev/md22" "/dev/sdb3" "/dev/sdc3"
#create_raid1 "/dev/md23" "/dev/sdb5" "/dev/sdc5"
#create_raid1 "/dev/md24" "/dev/sdb6" "/dev/sdc6"

create_raid 1

# Создание файла конфигурации mdadm.conf
echo "DEVICE partitions" > /etc/mdadm.conf
mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm.conf
