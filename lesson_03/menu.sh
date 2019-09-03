#!/usr/bin/env bash

REPORT_LOG=report_lvm.log   # Файл, в который будет логироваться ход выполнения всех заданий
STAGE_LOG=/home/vagrant/stage.log         # Файл, в который записывается уровенеь проведенных изменений, чтобы после перезагрузки системы не начинать все сначала


STAGE=

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


if [ ! -f $STAGE_LOG ]; then
   echo "Выполнять нечего (файл '$STAGE_LOG' не существует)."
   exit 1
else
    STAGE=`cat $STAGE_LOG`
    case $STAGE in
        0)  report "Исходная система"
            echo "1" > $STAGE_LOG
            lvm_create_tmp_root
            lvm_move_to_tmp_root
            lvm_reconfig_grub2 $VG $LV $TMP_VG $TMP_LV
            reboot
            ;;

        1)  report "Система с корнем на временном томе"
            echo "2" > $STAGE_LOG
            lvm_create_new_root
            lvm_move_to_new_root
            lvm_reconfig_grub2 $VG $LV $VG $NEW_LV
            reboot
            ;;

        2)  report "Система с уменьшенным корневым томом с ФС XFS"
            echo "3" > $STAGE_LOG
            lvm_del_tmp_root
            lvm_create_new_var
            lvm_move_to_new_var
            lv_create_new_home
            ;;

        3)  echo "Текущий уровень 3"
            ;;

        *)  echo "Ошибка в файле $STAGE_LOG"
            exit 1
            ;;
    esac
fi
