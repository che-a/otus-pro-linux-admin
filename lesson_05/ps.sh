#!/usr/bin/env bash

PROGNAME=`basename $0`
# Массив PID заполняем идентификаторами процессов из каталога /proc/
PIDS=(`ls /proc/ | grep "^[0-9]" | sort -n`)
TTY=
STAT=
TIME=
CMD=

function get_tty {

    return
}

function ps_ax {


    echo "  PID TTY      STAT   TIME COMMAND"

    # Последовательно перебираем массив с идентификаторами процессов
    for PID in ${PIDS[@]}; do
        # На момент перебора некоторых процесов уже может не существовать
        if [ -d "/proc/$PID" ]; then
            # Колонка TTY
            get_tty
            #TTY=`cat /proc/$PID/stat | gawk '{print $7}'`
            #if [ $TTY == 0 ]; then
            #    TTY='?'
            #fi
            # Колонка STAT
            STAT=`cat /proc/$PID/status | grep State | gawk '{print $2}'`
            # Колонка TIME
            TIME='X:XX'
            # Колонка CMD
            CMD=`cat /proc/$PID/cmdline | tr '\0' ' '`
            if [[ -z $CMD ]]; then
                CMD='['`cat /proc/$PID/status | grep Name | gawk '{print $2}'`']'
            else
                CMD=`echo $CMD | awk '{print substr ($0, 0, 60)}'`
            fi

            # Команда printf некорректно выводит заданное число символов строки,
            # которые содержат пробелы
            printf "%5d %-8s %-6s %4s %s \n" $PID $TTY $STAT $TIME "$CMD"
        fi
    done
}

function print_usage {
    echo -e "\n$PROGNAME - реализация на bash программы ps ax"
    echo -e "Использование: $PROGNAME [ -ax | -h | -v ]\n"
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
