#!/usr/bin/env bash

# Домашнее задание №3
# STAGE 0       Первый запуск сценария, создание временного тома,
#               настройка загрузки с нового тома, перезагрузка
# STAGE 1       Загрузка с временного тома, удаление старого раздела,
#               создание нового раздела нужного размера

REPORT_LOG=report_lvm.log   # Файл, в который будет логироваться ход выполнения всех заданий
STAGE_LOG=/home/vagrant/stage.log         # Файл, в который записывается уровенеь проведенных изменений, чтобы после перезагрузки системы не начинать все сначала
REDUCE_TO_SIZE=8G           # Новый размер тома, ГБ
TMP_PV='/dev/sdb'           # Временный физческий том
TMP_VG='VG01'               #
TMP_LV='lv_tmp_root'        #
CUR_PV=
CUR_VG=
CUR_LV=
NEW_PV=
NEW_VG=
NEW_LV=
STAGE=

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
    for i in /proc/ /sys/ /dev/ /run/ /boot/; do
        mount --bind $i /mnt/$i;
    done
chroot /mnt/ /bin/bash <<'EOT'
grub2-mkconfig -o /boot/grub2/grub.cfg
# Обновление образа initrd
cd /boot;
for i in `ls initramfs-*img`; do
    dracut -v $i `echo $i|sed "s/initramfs-//g;s/.img//g"` --force;
done
EOT
    sed -i 's/rd.lvm.lv=VolGroup00/LogVol00 =.*/rd.lvm.lv=VG01/lv_tmp_root/' /boot/grub2/grub.cfg
    # reboot
    #

    #
}


#touch $REPORT_LOG; output_log "Исходная система"

#reduce_size_root
#output_log "Уменьшение тома с корневой ФС"


if [ ! -f $STAGE_LOG ]; then
   echo "Файл '$STAGE_LOG' не существует. Выполнять нечего."
   exit 1
else
    STAGE=`cat $STAGE_LOG`

    case $STAGE in
        0)  echo "Текущий уровень: 0"
            ;;
        1)  echo "Текущий уровень: 1"
            ;;
        2)  echo "Текущий уровень: 2"
            ;;
        *)  echo "Ошибка в файле $STAGE_LOG"
            exit 1
            ;;
    esac
fi
