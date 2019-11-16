#!/usr/bin/env bash

WATCHLOG_NAME='che-les08-watchlog'
WATCHLOG_SCRIPT='/opt/'$WATCHLOG_NAME'.sh'
SYSCONFIG_FILE='/etc/sysconfig/'$WATCHLOG_NAME

KEY_WORD='ALERT'

function system_prepare
{
    yum install -y mc nano
}

function watchlog_create_sysconfig_file
{
    (
        echo "WORD=$KEY_WORD"
        echo "LOG=$LOG_FILE"
    ) > $SYSCONFIG_FILE
}

function watchlog_create_script
{
    (
        echo '#!/usr/bin/env bash'
        echo 'WORD=$1'
        echo 'LOG=$2'
        echo 'DATE=`date`'
        echo 'if grep $WORD $LOG &> /dev/null'
        echo 'then'
        echo '    logger "$DATE: I found word, Master!"'
        echo 'else'
        echo '    exit 0'
        echo 'fi'
    ) > $WATCHLOG_SCRIPT

    chmod +x $WATCHLOG_SCRIPT
}

function watchlog_fill_log_file
{
    (
        echo "ALARM"
        echo "ALERT"
        echo "1984"
    ) > $LOG_FILE
}

#
# *****************************************************
#

system_prepare

watchlog_create_sysconfig_file
watchlog_create_script
watchlog_fill_log_file
