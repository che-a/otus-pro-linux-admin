#!/usr/bin/env bash

# Домашнее задание №3
# +-------+--------------------------------------------------------------------+
# | STAGE |                       Описание                                     |
# +-------+--------------------------------------------------------------------+
# |   0   | Первый запуск сценария, создание временного тома,                  |
# |       | настройка загрузки с нового тома, перезагрузка                     |
# +-------+--------------------------------------------------------------------+
# |   1   | Загрузка с временного тома, удаление старого раздела,
# |       | создание нового раздела нужного размера
# +-------+--------------------------------------------------------------------+

REPORT_LOG=report_lvm.log   # Файл, в который будет логироваться ход выполнения всех заданий
STAGE_LOG=/home/vagrant/stage.log         # Файл, в который записывается уровенеь проведенных изменений, чтобы после перезагрузки системы не начинать все сначала

NEW_SIZE=8G           # Новый размер тома, ГБ

PV='/dev/sda3'
VG='VolGroup00'
LV='LogVol00'

TMP_PV='/dev/sdb'           # Временный физческий том
TMP_VG='VGTMP'               #
TMP_LV='lv_tmp'        #

#NEW_LV='lv_reduce_root'

STAGE=

#
# Логирование вывода информационных команд с целью отслеживания изменений
# по ходу выполнения задания
function report {
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

# Создание временного корневого раздела и копирование на него данных из текущего
function lvm_create_tmp_root {
    # Создание временного тома
    pvcreate $TMP_PV
    vgcreate $TMP_VG $TMP_PV
    lvcreate -n $TMP_LV -l +100%FREE /dev/$TMP_VG

    # Создание ФС на временном томе и монтирование ее
    mkfs.xfs /dev/$TMP_VG/$TMP_LV
    mount /dev/$TMP_VG/$TMP_LV /mnt

    # Копирование всех файлов текущего тома корневого каталога на временный том
    xfsdump -J - /dev/$VG/$LV | xfsrestore -J - /mnt

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
    sed -i "s+rd.lvm.lv=$VG/$LV+rd.lvm.lv=$TMP_VG/$TMP_LV+" \
        /boot/grub2/grub.cfg
}

function lvm_create_new_root {
    lvremove /dev/$VG/$LV --force
    lvcreate -n $LV -L $NEW_SIZE /dev/$VG

    mkfs.xfs /dev/$VG/$LV
    mount /dev/$VG/$LV /mnt

    xfsdump -J - /dev/$TMP_VG/$TMP_LV | xfsrestore -J - /mnt

    for i in /proc/ /sys/ /dev/ /run/ /boot/; do
        mount --bind $i /mnt/$i;
    done

chroot /mnt/ /bin/bash <<'EOT'
grub2-mkconfig -o /boot/grub2/grub.cfg
cd /boot ;
for i in `ls initramfs-*img`; do
    dracut -v $i `echo $i|sed "s/initramfs-//g;s/.img//g"` --force;
done
EOT
#    sed -i "s+rd.lvm.lv=$TMP_VG/$TMP_LV+rd.lvm.lv=$VG/$NEW_LV+" \
#        /boot/grub2/grub.cfg
}


if [ ! -f $STAGE_LOG ]; then
   echo "Выполнять нечего (файл '$STAGE_LOG' не существует)."
   exit 1
else
    STAGE=`cat $STAGE_LOG`
    case $STAGE in
        0)  report "Исходная система, копирование на временный том"
            echo "1" > $STAGE_LOG
            lvm_create_tmp_root
            reboot
            ;;

        1)  report "Создание нового тома, копирование на него файлов с временного"
            echo "2" > $STAGE_LOG
            lvm_create_new_root
            reboot
            ;;

        2)  report "Размер корневого раздела с ФС XFS уменьшен"
            ;;

        *)  echo "Ошибка в файле $STAGE_LOG"
            exit 1
            ;;
    esac
fi
