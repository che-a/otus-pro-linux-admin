#!/usr/bin/env bash

function system_prepare
{
    yum install -y epel-release
    yum install -y mc nano tmux tree wget
}

function customize_mariadb
{
    yum install -y mariadb


}

function customize_apache
{
    yum install -y httpd httpd-devel php-mysql php-pear php-common php-gd \
        php-devel php php-mbstring php-cli

}

function  customize_cacti
{
    yum install -y cacti php-snmp net-snmp-utils net-snmp-libs rrdtool


}

system_prepare
#customize_mariadb
#customize_apache
