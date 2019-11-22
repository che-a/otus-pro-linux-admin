#!/usr/bin/env bash

# Запускать данный сценарий необходимо от пользователя root (su или sudo не
# использовать) и из директории /root

REPORT_FILE=/root/report.log

VG='VolGroup00'
LV='lv_home'
SIZE='100M'
SNAP_NAME='home_snap'

# Логирование в файл вывода команд
function report {
    local CMDS=('lsblk' \
                'lvs -v' \
                'ls -al /home' \
    )

    for i in $(seq 1 80); do echo -n "*" >> $REPORT_FILE; done
    (echo ; echo "**** $1:") >> $REPORT_FILE
    for i in $(seq 1 80); do echo -n "*" >> $REPORT_FILE; done
    echo >> $REPORT_FILE

    for i in "${CMDS[@]}"; do
        (echo ==== $i ====; sh -c "$i") >> $REPORT_FILE;
    done
}

report "Исходное состояние:"

# Наполнение тома /home ненулевыми файлами
for i in $(seq 1 20);do
    touch /home/file$i
    echo "OTUS. Адинистратор Linux" >> /home/file$i
done
report "Создание тестовых файлов:"

lvcreate -L $SIZE -s -n $SNAP_NAME /dev/$VG/$LV
report "После создания снапшота:"

# Удаление части тестовых файлов для демонстрации восстановления со снапшота
rm -f /home/file{11..20}
report "Удаление части тестовых файлов:"
umount /home

lvconvert --merge /dev/$VG/$SNAP_NAME
mount /home
report "После восстановления из снапшота:"
