#!/usr/bin/env bash

function system_prepare
{
    yum install -y mc nano tree
}

function files_prepare
{
    /bin/cp -rf /vagrant/include/* /
    chmod +x /opt/{generator,watcher}.sh
    touch /var/log/generator.log
    #chown vagrant:vagrant /var/log/generator.log

    systemctl daemon-reload
    systemctl enable generator.service
    systemctl enable generator.timer
    systemctl enable watcher.service
    systemctl enable watcher.timer
    systemctl start generator.service
    systemctl start generator.timer
    systemctl start watcher.service
    systemctl start watcher.timer
}

system_prepare
files_prepare
