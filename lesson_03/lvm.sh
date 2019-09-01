#!/usr/bin/env bash

# Файл, в который будет логироваться ход выполнения всех заданий
REPORT_LOG=report_lvm.log
REDUCE_TO_SIZE=8        # Новый размер тома, ГБ
TMP_PV='/dev/sdb'       # Временный физческий том
TMP_VG='VG01'           #
TMP_LV='lv_tmp_root'    #

# Логирование вывода информационных команд с целью отслеживания изменений
# по ходу выполнения задания
function output_log {
    local CMDS=('lsblk' \
                'df -h -x tmpfs -x devtmpfs' \
                'pvs' \
                'vgs' \
                'lvs' )

    for i in $(seq 1 80); do echo -n "#" >> $REPORT_LOG; done
    (echo ; echo "#### $1:") >> $REPORT_LOG
    for i in $(seq 1 80); do echo -n "#" >> $REPORT_LOG; done
    echo >> $REPORT_LOG

    for i in "${CMDS[@]}"; do
        (echo ========== $i ==========; sh -c "$i") >> $REPORT_LOG;
    done
}

# Уменьшение размера тома корневого каталога с файловой системой XFS
function reduce_size_root() {

    # Создание временного тома
    pvcreate $TMP_PV
    vgcreate $TMP_VG $TMP_PV
    lvcreate -n $TMP_LV -l +100%FREE /dev/$TMP_VG

    # Создание ФС на временном томе и монтирование ее
    mkfs.xfs /dev/$TMP_VG/$TMP_LV
    mount /dev/$TMP_VG/$TMP_LV /mnt

    # Копирование всех файлов текущего тома корневого каталога на временный том
    xfsdump -J - /dev/VolGroup00/LogVol00 | xfsrestore -J - /mnt

    # Переконфигурирование grub, чтобы после рестарта временный том был корнем ФС
    for i in /proc/ /sys/ /dev/ /run/ /boot/; do mount --bind $i /mnt/$i; done
    # chroot /mnt/
    # grub2-mkconfig -o /boot/grub2/grub.cfg
    # Обновим образ initrd
    # cd /boot ; for i in `ls initramfs-*img`; do dracut -v $i `echo $i|sed "s/initramfs-//g;s/.img//g"` --force; done
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


touch $REPORT_LOG; output_log "Исходная система"

reduce_size_root
output_log "Уменьшение тома с корневой ФС"
