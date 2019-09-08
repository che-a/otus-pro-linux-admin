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
    #echo "" > $X_IP_FILE

    #while read LINE; do
    #    IP=`echo $LINE | cut -d' ' -f1`
#        #echo $LINE | cut -d' ' -f1
#        echo $IP
#
#    done < $LOG_FILE


    local count=1

    for i in ${ALL_IP[@]}; do
        X_IP[$i]=0
        echo "$count. $i : ${X_IP[$i]}"
        count=$((count+1))
    done

    echo "Всего IP-адресов: "$ALL_IP_COUNT


}

get_x_ip
