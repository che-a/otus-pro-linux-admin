#!/usr/bin/env bash

function sys_prepare {
    echo "Running slave.sh"

    yum install -y epel-release
    yum install -y nano mc

    echo -e "192.168.1.100\tmaster\tmaster" >> /etc/hosts
}

sys_prepare
