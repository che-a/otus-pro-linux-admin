#!/usr/bin/env bash

# Подготовка системы
yum update -y
yum install -y mc nano wget ncurses-devel openssl-devel bc install libelf-dev, libelf-devel
yum groupinstall -y "Development Tools"

#
uname -r >> kernel_versions.log

cd /usr/src/kernels
wget https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-4.19.61.tar.xz
tar -xvf linux-4.19.61.tar.xz -C .

# cp /boot/config* .config
# make oldconfig
# make
# make install
# make modules_install
