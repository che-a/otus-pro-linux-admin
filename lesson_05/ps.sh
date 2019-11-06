#!/usr/bin/env bash

PROGNAME=`basename $0`

function print_usage {
    echo -e "\n$PROGNAME - реализация на bash программы ps ax"
    echo -e "Использование: $PROGNAME [ -ax | -h | -v ]\n"
}

function ps_ax {
    local PIDS=(`ls /proc/ | grep "^[0-9]" | sort -n`)
    local TTY=
    local STAT=
    local TIME=
    local CMD=

    echo -e "PID\tTTY\tSTAT\tTIME\tCOMMAND"

    for PID in ${PIDS[@]}; do
        if [ -d "/proc/$PID" ]; then
            TTY=`cat /proc/$PID/stat | gawk '{print $7}'`
            STAT=`cat /proc/$PID/stat | gawk '{print $3}'`
            CMD=`cat /proc/$PID/cmdline | tr '\0' ' '`
            if [[ -z $CMD ]]; then
                CMD=`cat /proc/$PID/stat | gawk '{print $2}'`
            fi
            echo -e "$PID\t$TTY\t$STAT\t$TIME\t$CMD"
        fi
    done
}


case $1 in
    -ax)                ps_ax
                        ;;

    -h | --help)        print_usage
                        ;;

    -v)                 echo "Админитсратор Linux"
                        ;;

    *)                  print_usage >&2
                        exit 1
                        ;;
esac
