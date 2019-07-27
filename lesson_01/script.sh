#!/usr/bin/env bash

# Подготовка системы
yum update -y
yum install -y epel-release
yum install -y htop lshw mc

#
uname -r >> kernel_versions.txt
