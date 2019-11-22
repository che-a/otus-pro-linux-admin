#!/usr/bin/env bash

function task1
{
    /bin/cp -rf /vagrant/include/* /
    chmod +x /opt/{generator,watcher}.sh
    touch /var/log/generator.log

    systemctl daemon-reload
    systemctl enable {generator,watcher}.timer
    systemctl start {generator,watcher}.timer
}

function task2
{
    yum install -y epel-release
    yum install -y spawn-fcgi php php-cli mod_fcgid httpd

    sed -i 's/#SOCKET/SOCKET/' /etc/sysconfig/spawn-fcgi
    sed -i 's/#OPTIONS/OPTIONS/' /etc/sysconfig/spawn-fcgi

    systemctl daemon-reload
    systemctl enable spawn-fcgi
    systemctl start spawn-fcgi
}

function task3
{
    cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd-inst1.conf
    cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd-inst2.conf

    sed -i 's/Listen 80/Listen 8080/' /etc/httpd/conf/httpd-inst2.conf
    sed -i '/ServerRoot "\/etc\/httpd"/a PidFile \/var\/run\/httpd-inst2.pid' \
        /etc/httpd/conf/httpd-inst2.conf

    systemctl daemon-reload
    systemctl start httpd@inst1
    systemctl start httpd@inst2
}

yum install -y mc nano tree

task1
task2
task3
