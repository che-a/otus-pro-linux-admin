#!/usr/bin/env bash

NUMS=(  '1025' \
        '1031' \
        '34816' \
        '34817' \
        '34818' \
        '34819')

BIN_MAJOR=
BIN_MINOR=
BIN_NUM=
DEVS=

for NUM in ${NUMS[@]}; do
    #printf  "%016d %d Major=%d \n" \
    #        `echo "obase=2;$NUMBER" | bc` \
    #        $NUMBER \
    #        `echo "obase=2;$NUMBER" | bc | awk '{print substr ($0, 0, 8)}'`
    BIN_NUM=$( printf "%016d" `echo "obase=2;$NUM" | bc` )
    BIN_MAJOR=`echo $BIN_NUM | awk '{print substr ($0, 0, 8)}'`
    BIN_MINOR=`echo $BIN_NUM | awk '{print substr ($0, 9, 16)}'`
    MAJOR=`echo "ibase=2;$BIN_MAJOR" | bc`
    MINOR=`echo "ibase=2;$BIN_MINOR" | bc`

    case $MAJOR in
        '4')                DEVS='tty/'$MINOR
                            ;;

        '136')              DEVS='pts/'$MINOR
                            ;;


        *)                  DEVS='?'
                            exit 1
                            ;;
    esac

    #DEVS=`cat /proc/devices | grep $MAJOR | gawk '{print $2}'`
    printf "%6d %s %s %s %5d %5d %s \n" \
        $NUM \
        $BIN_NUM \
        $BIN_MAJOR \
        $BIN_MINOR \
        `echo "ibase=2;$BIN_MAJOR" | bc` \
        `echo "ibase=2;$BIN_MINOR" | bc` \
        $DEVS
done

#cat /proc/devices | grep

#+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
#|31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|||||
