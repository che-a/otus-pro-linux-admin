#!/usr/bin/env bash

VG_OLD=`vgdisplay | grep "VG Name" | gawk '{print $3}'`
VG_NEW='CheLes07Root'

REPORT_FILE='/home/vagrant/vg_rename.log'
UNIT_FILE='/etc/systemd/system/vg_rename.service'


function make_systemd_service
{
    touch $UNIT_FILE
    chmod 664 $UNIT_FILE

cat > $UNIT_FILE <<'_EOF_'
[Unit]
Description=Volume Group Rename
After=network.target
[Service]
Type=oneshot
User=root
ExecStart=/home/vagrant/vg_rename.sh
[Install]
WantedBy=multi-user.target
_EOF_

    systemctl enable $UNIT_FILE
}

function report
{
    (
        pvs; echo
        vgs; echo
        lvs; echo
    ) >> $REPORT_FILE
}


if [ -s $REPORT_FILE ]; then
    systemctl disable vg_rename.service
    echo "========== AFTER RENAMING VG ==========" >> $REPORT_FILE
    report
else
    make_systemd_service
    echo "========== BEFORE RENAMING VG ==========" > $REPORT_FILE
    report
    vgrename $VG_OLD $VG_NEW

    sed -i "s/$VG_OLD/$VG_NEW/g" /etc/fstab
    #sed -i "s/$VG_OLD/$VG_NEW/g" /etc/default/grub
    sed -i "s/$VG_OLD/$VG_NEW/g" /boot/grub2/grub.cfg

    #mkinitrd -f -v /boot/initramfs-$(uname -r).img $(uname -r)
    dracut -f -v

    echo "Reboot virtual machine ..."
    reboot
fi
