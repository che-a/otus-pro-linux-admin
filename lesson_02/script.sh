#!/usr/bin/env bash

LOG_FILE=report.log
OUTFILE=finish.sh
DISKS=("/dev/sdb" "/dev/sdc" "/dev/sdd" "/dev/sde")
RAID_LEVEL=5

# Логирование вывода команд для последующего составления отчета в README.md
function output_log {

    local CMDS=('lsblk' 'lshw -short | grep disk' 'df -h -x tmpfs -x devtmpfs' 'blkid' 'cat /proc/mdstat')
    for i in "${CMDS[@]}"; do
        ( echo ==== $i ====; sh -c "$i" ) >> $LOG_FILE
    done
}

# Разметка дисков
function prepare_disks {
    for i in ${DISKS[@]}; do
        parted -s $i mktable gpt
        parted -s $i mkpart primary 2048s 4096s   # GPT-раздел
        parted -s $i set 1 bios_grub on
        parted -s $i mkpart primary ext4 4M 100%  # раздел для RAID
    done
    output_log
}

# Создание RAID одного из уровней 0/1/5/6/10
function create_raid {

    case $1 in
        0)  echo "Creating RAID 0"
            mdadm --create --verbose /dev/md$1 --force --level=0 --raid-devices=2 /dev/sd{b2,c2}
            ;;
        1)  echo "Creating RAID 1"
            mdadm --create --verbose --metadata=1.2 /dev/md$1 --force --level=1 --raid-devices=3 /dev/sd{b2,c2,d2}
            mdadm /dev/md$1 --add /dev/sde2
            ;;
        5)  echo "Creating RAID 5"
            mdadm --create --verbose /dev/md$1 --level=5 --raid-devices=4 /dev/sd{b2,c2,d2,e2}
            ;;
        6)  echo "Creating RAID 6"
            mdadm --create --verbose /dev/md$1 --level=6 --raid-devices=4 /dev/sd{b2,c2,d2,e2}
            ;;
        10) echo "Creating RAID 10"
            mdadm --create --verbose /dev/md$1 --level=10 --raid-devices=4 /dev/sd{b2,c2,d2,e2}
            ;;
        *)  echo "Invalid RAID level!" >&2
            exit 1
            ;;
    esac

    # Создание разделов на RAID`е
    parted -s /dev/md$1 mktable gpt
#    parted -s /dev/md$1 mkpart primary 2048s 4096s      #GPT-раздел
#    parted -s /dev/md$1 set 1 bios_grub on
    parted -s /dev/md$1 mkpart primary ext4 4M 5%       #раздел №1
    parted -s /dev/md$1 mkpart primary ext4 5% 10%      #раздел №2
    parted -s /dev/md$1 mkpart primary ext4 10% 25%     #раздел №3
    parted -s /dev/md$1 mkpart primary ext4 25% 50%     #раздел №4
    parted -s /dev/md$1 mkpart primary ext4 50% 100%    #раздел №5

    # Монтирование разделов
    for i in $(seq 1 5); do
        mkdir -p /mnt/raid/md$1p$i
        mkfs.ext4 /dev/md$1p$i
        mount /dev/md$1p$i /mnt/raid/md$1p$i
    done

    # Создание файла конфигурации mdadm.conf
    echo "DEVICE partitions" > /etc/mdadm.conf
    mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm.conf

    output_log
}

# Подготовка к переносу "живой" системы с одним разделом
# на RAID с несколькими разделами
function transfer_to_raid {

    # Размонтирование разделов и удаление ненужных директорий,
    # оставшихся при выполнении предыдущего задания
    for i in $(seq 1 5); do
        umount /dev/md$1p$i
        rmdir /mnt/raid/md$1p$i
    done
    rmdir /mnt/raid

    # Перенос системы на RAID
    mkfs.ext4 /dev/md$1
    mount /dev/md$1 /mnt/
    rsync -axu --progress --exclude /swapfile --exclude /vagrant / /mnt/
}

# Формирование сценария, который необходимо запустить вручную после
# развертывания тестового окружения
function gen_finish_script {
    (
    cat << '_EOF_'
#!/usr/bin/env bash

mount --bind /proc /mnt/proc
mount --bind /dev /mnt/dev
mount --bind /sys /mnt/sys
mount --bind /run /mnt/run
chroot /mnt/ /bin/bash <<'EOT'
# /etc/fstab
RAID_NAME=`cat /proc/mdstat |grep md | cut -d" " -f1`
(
echo -n `blkid |grep $RAID_NAME | cut -d" " -f 2`
echo '  /   ext4    defaults         0 0'
) >> /etc/fstab
# mdadm.conf
echo "DEVICE partitions" > /etc/mdadm.conf
mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm.conf
sed -i 's/SELINUX=.*/SELINUX=permissive/' /etc/selinux/config
sed -i 's/GRUB_CMDLINE_LINUX=.*/GRUB_CMDLINE_LINUX="no_timer_check console=tty0 console=ttyS0,115200n8 net.ifnames=0 biosdevname=0 elevator=noop crashkernel=auto rd.auto=1"/' /etc/default/grub
dracut --force /boot/initramfs-$(uname -r).img $(uname -r)
grub2-mkconfig -o /boot/grub2/grub.cfg && \
grub2-install /dev/sdb && grub2-install /dev/sdc
EOT

_EOF_
    ) > $1
    chmod +x $1

}


yum install -y mdadm smartmontools hdparm gdisk nano tree
touch $LOG_FILE
output_log

prepare_disks && create_raid $RAID_LEVEL
transfer_to_raid $RAID_LEVEL && gen_finish_script $OUTFILE
