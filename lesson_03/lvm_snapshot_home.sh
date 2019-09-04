#!/usr/bin/env bash

VG='VolGroup00'
LV='lv_home'
SIZE='100M'
SNAP_NAME='home_snap'

for i in $(seq 1 20);do
    touch /home/file$i
    echo "OTUS. Адинистратор Linux" >> /home/file$i
done

lvcreate -L $SIZE -s -n $SNAP_NAME /dev/$VG/$LV

rm -f /home/file{11..20}

umount /home

lvconvert --merge /dev/$VG/$SNAP_NAME

mount /home
