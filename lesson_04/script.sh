#!/usr/bin/env bash

LOG_FILE='access.log'
#LOG_FILE='access-4560-644067.log'
TMP_X_FILE='/tmp/x.tmp'
TMP_Y_FILE='/tmp/y.tmp'
TMP_ERRORS_FILE='/tmp/errors.tmp'
TMP_CODES_FILE='/tmp/codes.tmp'

X='7'
Y='15'

RETURN_CODES=(  [100]='Continue' \
                [101]='Switching Protocols' \
                [102]='Processing' \
                [200]='OK' \
                [201]='Created' \
                [202]='Accepted' \
                [203]='Non-Authoritative Information' \
                [204]='No Content («нет содержимого»)[2][3]' \
                [205]='Reset Content («сбросить содержимое»)' \
                [206]='Partial Content («частичное содержимое»)' \
                [207]='Multi-Status («многостатусный»)' \
                [208]='Already Reported («уже сообщалось»)' \
                [226]='IM Used («использовано IM»)' \
)


function get_x {
    gawk '
                {
                    count[$1]++
                }

        END     {
                    for (ip in count) print count[ip], ip
                }
    ' $LOG_FILE | sort -n -r | head -n $X |
    gawk '
        BEGIN   {
                    print "----+-----------------+---------------------"
                    print "  № |     IP-адрес    |Макс.кол-во запросов "
                    print "----+-----------------+---------------------"
                    i = 0
                }

                {
                    # Меняем столбцы местами
                    tmp_str = $1
                    $1 = $2
                    $2 = tmp_str
                    printf "%4d| %-16s|%11d\n", ++i, $1, $2
                }

        END     {
                    print "----+-----------------+---------------------"
                }
    ' > $TMP_X_FILE
}

function get_y {

    return 0
}

function all_errors {

    return 0
}

function all_return_codes {
    cat $LOG_FILE | cut -d " " -f 6-9 | cut -d '"' -f 3 | cut -d " " -f 2 | \
        sort -n | uniq -c |
    gawk '
        BEGIN   {
                    print "----+---------------+--------"
                    print "  № | Код состояния | Кол-во "
                    print "    |      HTTP     |        "
                    print "----+---------------+--------"
                    i = 0
                }

                {
                    printf "%4d| %13d | %4d \n", ++i, $2, $1
                }

        END     {
                    print "----+---------------+--------"
                }
    ' > $TMP_CODES_FILE
}
get_x
# get_y
all_return_codes
# all_errors
