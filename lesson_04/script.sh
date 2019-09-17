#!/usr/bin/env bash

# Согласно условию задания необходимо использовать утилиту find.
# Здесь она используется для поиска файла export.txt, содержащего некоторые
# переменные и их значения.
EXPORT_FILE=`find / -name export.txt 2>/dev/null`
LOG_NAME_FULL=`gawk 'BEGIN {FS = "="} /LOG_NAME_FULL/ {print $2}' $EXPORT_FILE`
SCRIPT_DIR=`gawk 'BEGIN {FS = "="} /SCRIPT_DIR/ {print $2}' $EXPORT_FILE`
STR_NUM_FILE_FULL=`gawk 'BEGIN {FS = "="} /STR_NUM_FILE_FULL/ {print $2}' $EXPORT_FILE`

STR_PREV=`gawk '{print}' $STR_NUM_FILE_FULL`
STR_CURR=

# Файл блокировки для защиты сценария от повторного запуска
LOCKFILE=$SCRIPT_DIR"file.lock"

# Промежуточные файлы для отдельных заданий по сбору статистики лог-файла
TMP_X_FILE=$SCRIPT_DIR"x.tmp"
TMP_Y_FILE=$SCRIPT_DIR"y.tmp"
TMP_CODES_FILE=$SCRIPT_DIR"codes.tmp"
TMP_REPORT_FILE=$SCRIPT_DIR"report.tmp"
# Массив с именами временных файлов для их более удобного удаления
TMP_FILES=($TMP_X_FILE $TMP_Y_FILE $TMP_CODES_FILE $TMP_REPORT_FILE)

X='10'  # Число IP-адресов с наибольшим количеством запросов
Y='15'  # Число запрашиваемых адресов с наибольшим количеством запросов

USER="root"
DOMAIN="localhost"
MAIL=$USER'@'$DOMAIN

function create_report_header {
    local TIME_FROM=`gawk 'NR == '"$STR_PREV"' {print $4}' $LOG_NAME_FULL | cut -d"[" -f2`
    local TIME_TO=`gawk 'NR == '"$STR_CURR"' {print $4}' $LOG_NAME_FULL | cut -d"[" -f2`

    echo    "$LOG_NAME_FULL" \
            $TIME_FROM \
            $TIME_TO \
            "$STR_PREV-$STR_CURR" \
            "$(( $STR_CURR - $STR_PREV + 1))" |
    gawk '
        {
            print  "+======================================================+"
            print  "|                    ОТЧЕТ                             |"
            print  "+--------+---------------------------------------------+"
            printf "| Файл:  | %-43s |\n", $1
            print  "+--------+---------------------------------------------+"
            printf "| Период:| %-43s |\n", $2
            printf "|        | %-43s |\n", $3
            print  "+--------+-----------------+------------------+--------+"
            printf "| Строки:| %-15s | Обработано строк:| %-6s |\n", $4, $5
            print  "+--------+-----------------+------------------+--------+\n"
        }
    ' >> $TMP_REPORT_FILE
}

# sudo tail -f -n 40 /var/spool/mail/root

function get_x {
    gawk 'NR == '"$STR_PREV"', NR =='"$STR_CURR"' { count[$1]++ }
        END { for (ip in count) print count[ip], ip }
    ' $LOG_NAME_FULL | sort -n -r | head -n $X |
    gawk '
        BEGIN {
            print "+=====+=================+==========+"
            print "|  X  |    IP-адрес     | Number of|"
            print "|     |                 | requests |"
            print "+-----+-----------------+----------+"
            i = 0
        }
        {   # Меняем столбцы местами
            tmp_str = $1
            $1 = $2
            $2 = tmp_str
            printf "| %3d | %-15s |  %6d  |\n", ++i, $1, $2
        }
        END {print "+-----+-----------------+----------+\n"}
    ' >> $TMP_REPORT_FILE
}

function get_y {
    cat $LOG_NAME_FULL | cut -d " " -f 6-9 | cut -d '"' -f 2,3 |
    gawk 'NR == '"$STR_PREV"', NR =='"$STR_CURR"'
        /^[A-Z]/    { count[$2]++ }
        END         { for (addr in count) print count[addr], addr }
    ' | sort -n -r | head -n $Y |
    gawk '
        BEGIN {
            print "+=====+========+====================================+"
            print "|  Y  | Num.of |             Address                 "
            print "|     |requests|                                     "
            print "+-----+--------+------------------------------------+"
            i = 0
        }
        { printf "| %3d | %6d | %-s\n", ++i, $1, $2 }
        END { print "+-----+--------+------------------------------------+\n" }
    ' > $TMP_Y_FILE
}

function all_return_codes {
    cat $LOG_NAME_FULL | cut -d " " -f 6-9 | cut -d '"' -f 3 | cut -d " " -f 2 | \
        sort -n | uniq -c |
    gawk '
        BEGIN {
            return_codes[100]="Continue"
            return_codes[101]="Switching Protocols"
            return_codes[102]="Processing"
            return_codes[200]="OK"
            return_codes[201]="Created"
            return_codes[202]="Accepted"
            return_codes[203]="Non-Authoritative Information"
            return_codes[204]="No Content"
            return_codes[205]="Reset Content"
            return_codes[206]="Partial Content"
            return_codes[207]="Multi-Status"
            return_codes[208]="Already Reported"
            return_codes[226]="IM Used"
            return_codes[300]="Multiple Choices"
            return_codes[301]="Moved Permanently"
            return_codes[302]="Moved Temporarily"
            return_codes[302]="Found"
            return_codes[303]="See Other"
            return_codes[304]="Not Modified"
            return_codes[305]="Use Proxy"
            return_codes[307]="Temporary Redirect"
            return_codes[308]="Permanent Redirect"
            return_codes[400]="Bad Request"
            return_codes[401]="Unauthorized"
            return_codes[402]="Payment Required"
            return_codes[403]="Forbidden"
            return_codes[404]="Not Found"
            return_codes[405]="Method Not Allowed"
            return_codes[406]="Not Acceptable"
            return_codes[407]="Proxy Authentication Required"
            return_codes[408]="Request Timeout"
            return_codes[409]="Conflict"
            return_codes[410]="Gone"
            return_codes[411]="Length Required"
            return_codes[412]="Precondition Failed"
            return_codes[413]="Payload Too Large"
            return_codes[414]="URI Too Long"
            return_codes[415]="Unsupported Media Type"
            return_codes[416]="Not Satisfiable"
            return_codes[417]="Expectation Failed"
            return_codes[418]="Im a teapot"
            return_codes[419]="Authentication Timeout"
            return_codes[421]="Misdirected Request"
            return_codes[422]="Unprocessable Entity"
            return_codes[423]="Locked"
            return_codes[424]="Failed Dependency"
            return_codes[426]="Upgrade Required"
            return_codes[428]="Required"
            return_codes[429]="Too Many Requests"
            return_codes[431]="Request Header Fields Too Large"
            return_codes[449]="Retry With"
            return_codes[451]="Unavailable For Legal Reasons"
            return_codes[452]="Bad sended request"
            return_codes[499]="Client Closed Request"
            return_codes[500]="Internal Server Error"
            return_codes[501]="Not Implemented"
            return_codes[502]="Bad Gateway"
            return_codes[503]="Service Unavailable"
            return_codes[504]="Gateway Timeout"
            return_codes[505]="HTTP Version Not Supported"
            return_codes[506]="Variant Also Negotiates"
            return_codes[507]="Insufficient Storage"
            return_codes[508]="Loop Detected"
            return_codes[509]="Bandwidth Limit Exceeded"
            return_codes[510]="Not Extended"
            return_codes[511]="Network Authentication Required"
            return_codes[520]="Unknown Error"
            return_codes[521]="Web Server Is Down"
            return_codes[522]="Connection Timed Out"
            return_codes[523]="Origin Is Unreachable"
            return_codes[524]="A Timeout Occurred"
            return_codes[525]="SSL Handshake Failed"
            return_codes[526]="Invalid SSL Certificate"

            i = 0
            flag_4xx = "false"
            flag_5xx = "false"

            print "+=====+=================================+========+"
            print "| No  |         HTTP status code        |  Count |"
            print "+-----+-----+---------------------------+--------+"
        }
        NR == '"$STR_PREV"', NR =='"$STR_CURR"'  {
            if ($2 ~ /4[0-9][0-9]/ && flag_4xx == "false" ){
                print "+-----+-----+---------------------------+--------+"
                print "|                -- Client error --              |"
                print "+-----+-----+---------------------------+--------+"
                flag_4xx = "true"
            }
            if ($2 ~ /5[0-9][0-9]/ && flag_5xx == "false" ){
                print "+-----+-----+---------------------------+--------+"
                print "|                -- Server error --              |"
                print "+-----+-----+---------------------------+--------+"
                flag_5xx = "true"
            }

            printf "|%4d | %3d | %-25s | %6d |\n", \
                ++i, $2, return_codes[$2], $1
        }
        END { print "+-----+-----+---------------------------+--------+\n" }
    ' > $TMP_CODES_FILE
}

function del_tmp_files {
    for FILE in ${TMP_FILES[@]}; do
        if [ -f $FILE ]; then
            rm $FILE
        fi
    done
}


trap 'exit 1' 1 2 3 15
trap 'del_tmp_files' 0

if [ -f $LOCKFILE ]; then
    echo "Ошибка запуска! Уже работает другая копия этого сценария."
    exit -1
else
    touch $LOCKFILE

    # Определение номера последней строки в лог-файле на момент запуска сценария
    STR_CURR=`gawk 'END {print NR}' $LOG_NAME_FULL`

    create_report_header
    get_x
    get_y
    all_return_codes

    # Отправка отчета
    cat $TMP_REPORT_FILE | mail -s "REPORT" $MAIL
    # Запись в файл номера строки, с которой будут читаться записи лог-файла
    # при следующем щапуске сценария
    echo $(($STR_CURR + 1)) > $STR_NUM_FILE_FULL

    rm $LOCKFILE
fi
