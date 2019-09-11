#!/usr/bin/env bash

LOG_FILE='access.log'
# LOG_FILE='access-4560-644067.log'
TMP_X_FILE='/tmp/x.tmp'
TMP_Y_FILE='/tmp/y.tmp'
TMP_ERRORS_FILE='/tmp/errors.tmp'
TMP_CODES_FILE='/tmp/codes.tmp'

X='7'
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

                }

                {
                    printf "%4d| %13d | %4d | %-20s\n", ++i, $2, $1, return_codes[$2]
                }

        END     {
                    print "----+---------------+--------"
                }
    ' > $TMP_CODES_FILE
}

function all_errors {

    return 0
}


get_x
# get_y
all_return_codes
# all_errors
