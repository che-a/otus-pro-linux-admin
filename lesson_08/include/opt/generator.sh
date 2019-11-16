#!/usr/bin/env bash

WORD=$1
LOG_FILE=$2

DATE_TIME=`date "+%d/%b/%Y:%T %z"`
echo $DATE_TIME' - '$WORD'! Need to do homework faster !!!' >> $LOG_FILE
