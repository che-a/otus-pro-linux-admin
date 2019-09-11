#!/usr/bin/env bash

#LOG_FILE='access.log'
LOG_FILE='access-4560-644067.log'
TMP_X_FILE='/tmp/x.tmp'
TMP_Y_FILE='/tmp/y.tmp'
X='25'
Y='15'

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

get_x
get_y
