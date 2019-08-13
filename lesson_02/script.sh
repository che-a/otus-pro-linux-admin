#!/usr/bin/env bash

LOG_FILE=report.log

# Логирование вывода команд для последующего составления отчета в README.md
function output_log {
    echo "== CMD ==: lsblk" >> $LOG_FILE
    lsblk >> $LOG_FILE
    echo "---" >> $LOG_FILE

    echo '== CMD ==: lshw -short | grep disk' >> $LOG_FILE
    lshw -short | grep disk >> $LOG_FILE
    echo "---" >> $LOG_FILE

    echo '== CMD ==: df -h -x tmpfs -x devtmpfs' >> $LOG_FILE
    df -h -x tmpfs -x devtmpfs >> $LOG_FILE
    echo "---" >> $LOG_FILE

    echo '== CMD ==: blkid' >> $LOG_FILE
    blkid >> $LOG_FILE
    echo "---" >> $LOG_FILE

    echo '== CMD ==: cat /proc/mdstat' >> $LOG_FILE
    cat /proc/mdstat >> $LOG_FILE
    echo "---" >> $LOG_FILE
}

function init {
    yum update -y
    yum install -y mdadm smartmontools hdparm gdisk
    yum install -y nano wget tree mc

    touch $LOG_FILE
    output_log
}

# Создание RAID уровней 0/1/5/6/10 для тестирования
function raid {

    parted -s /dev/sdb mktable gpt
    parted -s /dev/sdb mkpart primary 2048s 4096s   # GPT-раздел
    parted -s /dev/sdb set 1 bios_grub on
    parted -s /dev/sdb mkpart primary ext4 4M 100%  # раздел для RAID

    parted -s /dev/sdc mktable gpt
    parted -s /dev/sdc mkpart primary 2048s 4096s   # GPT-раздел
    parted -s /dev/sdc set 1 bios_grub on
    parted -s /dev/sdc mkpart primary ext4 4M 100%  # раздел для RAID

    parted -s /dev/sdd mktable gpt
    parted -s /dev/sdd mkpart primary 2048s 4096s   # GPT-раздел
    parted -s /dev/sdd set 1 bios_grub on
    parted -s /dev/sdd mkpart primary ext4 4M 100%  # раздел для RAID

    parted -s /dev/sde mktable gpt
    parted -s /dev/sde mkpart primary 2048s 4096s   # GPT-раздел
    parted -s /dev/sde set 1 bios_grub on
    parted -s /dev/sde mkpart primary ext4 4M 100%  # раздел для RAID

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

    parted -s /dev/md$1 mktable gpt
#    parted -s /dev/md$1 mkpart primary 2048s 4096s      #GPT-раздел
#    parted -s /dev/md$1 set 1 bios_grub on
    parted -s /dev/md$1 mkpart primary ext4 4M 5%       #раздел №1
    parted -s /dev/md$1 mkpart primary ext4 5% 10%      #раздел №2
    parted -s /dev/md$1 mkpart primary ext4 10% 25%     #раздел №3
    parted -s /dev/md$1 mkpart primary ext4 25% 50%     #раздел №4
    parted -s /dev/md$1 mkpart primary ext4 50% 100%    #раздел №5

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

# Подготовка "живой" системы к переносу на RAID
function transfer_to_raid {

    # Удалеям ошметки предыдущего задания
    for i in $(seq 1 5); do
        umount /dev/md$1p$i
        rmdir /mnt/raid/md$1p$i
    done
    rmdir /mnt/raid

    mkfs.ext4   /dev/md$1p1
    mkfs.ext4   /dev/md$1p2
    mkswap      /dev/md$1p3
    mkfs.ext4   /dev/md$1p4
    mkfs.ext4   /dev/md$1p5

    mkdir -p /mnt/{boot,home,var}
    mount /dev/md$1p1 /mnt/boot
    mount /dev/md$1p2 /mnt/home
    mount /dev/md$1p4 /mnt/var
    mount /dev/md$1p5 /mnt/

    # Копируем рабочую систему в /mnt.
    rsync -axu /boot/ /mnt/boot/
    rsync -axu /home/ /mnt/home/
    rsync -axu /var/ /mnt/var/
    rsync   -axu --recursive --progress \
            --exclude /vagrant \
            --exclude /boot \
            --exclude /home \
            --exclude /var \
            --exclude swapfile / /mnt/

    #
    # Формирование скрипта, который необходимо запустить вручную после
    # развертывания тестового окружения
    local OUTFILE=continued_transfer.sh
    (
    cat << '_EOF_'
#!/usr/bin/env bash
mount --bind /proc /mnt/proc
mount --bind /dev /mnt/dev
mount --bind /sys /mnt/sys
mount --bind /run /mnt/run
chroot /mnt/ /bin/bash <<'EOT'
# Создание нового /etc/fstab
echo "# My scripted /etc/fstab" > /etc/fstab
echo -n `blkid |grep md1p1 | cut -d" " -f 2`  >> /etc/fstab
echo '  /boot   ext4    defaults         0       0' >> /etc/fstab
echo -n `blkid |grep md1p2 | cut -d" " -f 2`  >> /etc/fstab
echo '  /home   ext4    defaults         0       0' >> /etc/fstab
echo -n `blkid |grep md1p3 | cut -d" " -f 2`  >> /etc/fstab
echo '  /swap   swap    defaults         0       0' >> /etc/fstab
echo -n `blkid |grep md1p4 | cut -d" " -f 2`  >> /etc/fstab
echo '  /var    ext4    defaults         0       0' >> /etc/fstab
echo -n `blkid |grep md1p5 | cut -d" " -f 2`  >> /etc/fstab
echo '  /       ext4    defaults         0       0' >> /etc/fstab
# Создание файла конфигурации mdadm.conf
echo "DEVICE partitions" > /etc/mdadm.conf
mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm.conf
dracut --mdadmconf --force /boot/initramfs-$(uname -r).img $(uname -r)
grub2-mkconfig -o /boot/grub2/grub.cfg && \
grub2-install /dev/sdb && \
grub2-install /dev/sdc && \
grub2-install /dev/sdd && \
grub2-install /dev/sde
echo "SELINUX=permissive" >> /etc/selinux/config
EOT

_EOF_
    ) > $OUTFILE
    chmod +x $OUTFILE

}


init
raid 1
transfer_to_raid 1
