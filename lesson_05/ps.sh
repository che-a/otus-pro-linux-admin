#!/usr/bin/env bash

PROGNAME=`basename $0`

function print_usage {
    echo -e "\n$PROGNAME - реализация на bash программы ps ax"
    echo -e "Использование: $PROGNAME [ -ax | -h | -v ]\n"
}

function ps_ax {
    echo "PID TTY      STAT   TIME COMMAND"
    ls /proc/ | grep "^[0-9]" | sort -n
}


case $1 in
    -ax)                ps_ax
                        ;;

    -h | --help)        print_usage
                        ;;

    *)                  print_usage >&2
                        exit 1
                        ;;
esac
