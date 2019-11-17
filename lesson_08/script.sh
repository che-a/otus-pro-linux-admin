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
}

system_prepare
files_prepare

systemctl daemon-reload
systemctl enable {generator,watcher}.timer
systemctl start {generator,watcher}.timer
