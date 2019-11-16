#!/usr/bin/env bash

WORD=$1
LOG=$2
DATE=`date`

if grep $WORD $LOG &> /dev/null
    then
        logger "$DATE: I found word, Che!"
    else
        exit 0
fi
