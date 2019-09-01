#!/usr/bin/env bash

LOG_FILE=report.log # Файл, в который будет записано подробное логирование выполнения всех заданий
REDUCE_TO_SIZE=8    # Размер тома, до которого его нужно уменьшить

# Логирование вывода информационных команд с целью отслеживания изменений
# в дисковой подсистеме по мере выполнения заданий
function output_log {
    local CMDS=('lsblk' \
                'df -h -x tmpfs -x devtmpfs' \
                'blkid')

    for i in $(seq 1 80); do echo -n "*" >> $LOG_FILE; done
    (echo ; echo "**** $1:") >> $LOG_FILE
    for i in $(seq 1 80); do echo -n "*" >> $LOG_FILE; done
    echo >> $LOG_FILE

    for i in "${CMDS[@]}"; do
        (echo ==== $i ====; sh -c "$i") >> $LOG_FILE;
    done
}

# Уменьшение размера тома с корневой файловой системой формата XFS
function reduce_size_root() {
    #
    return
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
# yum update -y
yum install -y mdadm smartmontools hdparm gdisk
yum install -y xfsdump

touch $LOG_FILE; output_log "Исходная система"
