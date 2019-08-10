#!/usr/bin/env bash

# Создание RAID уровней 0/1/5/6/10 для тестирования
function test_raid {
    case $1 in
        0)  echo "Creating RAID 0"
            mdadm --create --verbose /dev/md$1 --force --level=0 --raid-devices=2 /dev/sd{b,c}
            ;;
        1)  echo "Creating RAID 1"
            mdadm --create --verbose --metadata=1.2 /dev/md$1 --force --level=1 --raid-devices=2 /dev/sd{b,c}
            mdadm /dev/md$1 --add /dev/sdd
            mdadm /dev/md$1 --add /dev/sde
            ;;
        5)  echo "Creating RAID 5"
            mdadm --create --verbose /dev/md$1 --level=5 --raid-devices=4 /dev/sd{b,c,d,e}
            ;;
        6)  echo "Creating RAID 6"
            mdadm --create --verbose /dev/md$1 --level=6 --raid-devices=4 /dev/sd{b,c,d,e}
            ;;
        10) echo "Creating RAID 10"
            mdadm --create --verbose /dev/md$1 --level=10 --raid-devices=4 /dev/sd{b,c,d,e}
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

# Подготовка "живой" системы к переносу на RAID
function transfer_to_raid {
    return
}

yum update -y
yum install -y mdadm smartmontools hdparm gdisk
yum install -y nano wget tree

test_raid 10

# Создание файла конфигурации mdadm.conf
echo "DEVICE partitions" > /etc/mdadm.conf
mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm.conf
