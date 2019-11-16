#!/usr/bin/env bash
LOG_FILE='/var/log/generator.log'
DATE_TIME=
RANDOM_NUM=
WORD='ALERT!!!'

while true; do
    RANDOM_NUM=`shuf -i 1-10 -n 1`
    DATE_TIME=`date "+%d/%b/%Y:%T %z"`

    if [ $RANDOM_NUM -eq 5 ]; then
        echo $DATE_TIME' - '$WORD' Need to do homework faster !!!' >> $LOG_FILE
    else
        echo $DATE_TIME' - Some event happened' >> $LOG_FILE
    fi


    sleep $RANDOM_NUM
done
