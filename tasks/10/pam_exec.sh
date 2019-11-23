#!/usr/bin/env bash

HARD_WORKERS_GROUP='admin'
# Значение $IS_IN_GROUP
# 0 - $PAM_USER не входит в группу $HARD_WORKERS_GROUP
# 1 - входит
IS_IN_GROUP=`groups $PAM_USER | grep -c $HARD_WORKERS_GROUP`
TODAY_NUM=`date +%u`    # Номер дня недели

if [ $IS_IN_GROUP -eq 1 ]; then
    exit 0
else
    if [ $TODAY_NUM -gt 5 ]; then
        exit 1
    else
        exit 0
    fi
fi
