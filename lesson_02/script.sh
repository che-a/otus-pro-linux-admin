#!/usr/bin/env bash

yum update -y
yum install -y mdadm smartmontools hdparm gdisk

# zap (destroy) GPT and MBR data structures
#sgdisk --zap-all /dev/sdb
#sgdisk --zap-all /dev/sdс

# clear partition table
#sgdisk -o /dev/sdb
#sgdisk -o /dev/sdс

#sgdisk -n 1:0:+1M --typecode=1:EF02 /dev/sdb
#sgdisk -n 2:0:+512M --typecode=2:8300 /dev/sdb
#sgdisk --largest-new=3 /dev/sdb

#sgdisk -n 1:0:+1M --typecode=1:EF02 /dev/sdс
#sgdisk -n 2:0:+512M --typecode=2:8300 /dev/sdс
#sgdisk --largest-new=3 /dev/sdс
