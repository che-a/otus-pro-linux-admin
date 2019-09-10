#!/usr/bin/env bash

#LOG_FILE='access.log'
LOG_FILE='access-4560-644067.log'
X_IP_FILE='x_ip.log'
X='10'
ALL_IP=`cat $LOG_FILE | cut -d" " -f1 | sort -n | uniq`
#ALL_IP_COUNT=`cat $LOG_FILE | cut -d" " -f1 | sort -n | uniq | wc -l`
ALL_IP_COUNT=`echo ${#ALL_IP[@]}`

declare -A X_IP

function get_x_ip {

}

get_x_ip
