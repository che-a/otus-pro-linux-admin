#!/usr/bin/env bash

INFO_STR='Реализация команды ps ax на bash'
PROGNAME=`basename $0`

function help {
    echo "Unknown parameter $1"
    echo "help ... "
}

function ps_ax {
    echo "ps с параметорм ax"
}

function debug {
    echo "DEBUG ==> Count of paremeters: $1"
    echo "DEBUG ==> Program name: $PROGNAME"
    echo "----------------------------------"
}


debug $#

if [[ $1 == ax ]]; then
    ps_ax
else
    help $1
fi
