#!/usr/bin/env bash

LOG_FILE=report.log # Файл, в который будет записано подробное логирование выполнения всех заданий

# Логирование вывода информационных команд с целью отслеживания изменений
# в дисковой подсистеме по мере выполнения заданий
function output_log {
    local CMDS=('lsblk' \
                'df -h -x tmpfs -x devtmpfs' \
                'blkid' \
                'pvs' \
                'vgs' \
                'lvs' )

    for i in $(seq 1 80); do echo -n "#" >> $LOG_FILE; done
    (echo ; echo "#### $1:") >> $LOG_FILE
    for i in $(seq 1 80); do echo -n "#" >> $LOG_FILE; done
    echo >> $LOG_FILE

    for i in "${CMDS[@]}"; do
        (echo ========== $i ==========; sh -c "$i") >> $LOG_FILE;
    done
}

# Уменьшение размера тома с корневой файловой системой формата XFS
function reduce_size_root() {
    local REDUCE_TO_SIZE=8      # Новый размер тома, ГБ
    local TMP_PV='/dev/sdb'     # Временный физческий том
    local TMP_VG='VG_TMP_ROOT'
    local TMP_LV='lv_tmp_root'

    # Создаем временный том на устройстве $TMP_PV для тома с корневой ФС
    pvcreate $TMP_PV
    vgcreate $TMP_VG $TMP_PV
    lvcreate -n $TMP_LV -l +100%FREE /dev/$TMP_VG

    # Создаем ФС на временном томе и монтируем ее
    mkfs.xfs /dev/$TMP_VG/$TMP_LV
    mount /dev/$TMP_VG/$TMP_LV /mnt

    # xfsdump -J - /dev/$TMP_VG/$TMP_LV | xfsrestore -J - /mnt

    # Затем переконфигурируем grub для того, чтобы при старте перейти в новый /
    # Сымитируем текущий root -> сделаем в него chroot и обновим grub
    #for i in /proc/ /sys/ /dev/ /run/ /boot/; do mount --bind $i /mnt/$i; done
    #chroot /mnt/
    #grub2-mkconfig -o /boot/grub2/grub.cfg

}

function new_volume() {
    #statements
    return
}

function set_mirror() {
    #statements
    return
}

function new_volume() {
    #statements
    return
}

function gen_files() {
    #statements
    return
}

function gen_files2() {
    #statements
    return
}


mkdir -p ~root/.ssh
cp ~vagrant/.ssh/auth* ~root/.ssh

cp /vagrant/{lvm,zfs}.sh /home/vagrant/
# yum update -y
#yum install -y mdadm smartmontools hdparm gdisk
#yum install -y xfsdump mc

#touch $LOG_FILE; output_log "Исходная система"

#reduce_size_root
#output_log "Уменьшение тома с корневой ФС"
