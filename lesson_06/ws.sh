#!/usr/bin/env bash

function sys_prepare {
    echo "Running slave.sh"

    yum install -y epel-release
    yum install -y nano mc

}

sys_prepare
