#!/usr/bin/env bash

WORD=$1
LOG=$2
COUNT=`cat $LOG | grep $WORD | wc -l`
DATE=`date`

if [ $COUNT -gt 0 ]; then
    logger "$DATE: I found $COUNT word(s), Che!"
fi
