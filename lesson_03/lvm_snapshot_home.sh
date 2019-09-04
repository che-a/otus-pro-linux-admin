#!/usr/bin/env bash

VG='VolGroup00'
LV='lv_home'
SIZE='100M'
SNAPSHOT='home_snap'

touch /home/file{1..20}

lvcreate -L $SIZE -s -n $SNAPSHOT /dev/$VG/$LV

rm -f /home/file{11..20}

umount /home

lvconvert --merge /dev/$VG/$SNAPSHOT

mount /home
