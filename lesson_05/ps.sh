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

    echo "  PID TTY      STAT   TIME COMMAND"

    for PID in ${PIDS[@]}; do
        if [ -d "/proc/$PID" ]; then
            TTY=`cat /proc/$PID/stat | gawk '{print $7}'`
            STAT=`cat /proc/$PID/status | grep State | gawk '{print $2}'`
            TIME='X:XX'
            CMD=`cat /proc/$PID/cmdline | tr '\0' ' '`
            if [[ -z $CMD ]]; then
                #CMD=`cat /proc/$PID/stat | gawk '{print $2}'`
                CMD='['`cat /proc/$PID/status | grep Name | gawk '{print $2}'`']'
            else
                CMD=`echo $CMD | awk '{print substr ($0, 0, 60)}'`
            fi
            printf "%5d %-8s %-6s %4s %s \n" $PID $TTY $STAT $TIME "$CMD"
            #printf "%5d %.40s \n" "$PID" "$CMD"
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
