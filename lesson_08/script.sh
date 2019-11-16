#!/usr/bin/env bash

function system_prepare
{
    yum install -y mc nano tree

    cp /vagrant/include/etc/systemd/system/generator.service \
        /etc/systemd/system/generator.service
    chmod 664 /etc/systemd/system/generator.service

    cp /vagrant/include/opt/generator.sh /opt/generator.sh
    chmod +x /opt/generator.sh

    touch /var/log/generator.log
    chmod 664 /var/log/generator.log
    chown vagrant:vagrant /var/log/generator.log

    systemctl enable generator.service
    systemctl start generator.service
}


#
# *****************************************************
#

system_prepare
