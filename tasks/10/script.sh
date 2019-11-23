#!/usr/bin/env bash

PROGNAME=`basename $0`
HARD_WORKERS_GROUP='admin'  # Группа пользователей с доступом в Сб и Вс
NEW_USERS=('dux' 'gex' 'rex')   # Обычные пользователи, без доступа в Сб и Вс
HARD_WORKERS=('vagrant' 'rex')  # Пользователи из группы $ADMIN_GROUP и,
                                # соответственно, с доступом в Сб и Вс

# Для вывода информации при вызове программы с параметром -h|--help
function print_usage {
    echo -e "\n$PROGNAME - Working with PAM"
    echo -e "Usage: $PROGNAME [ OPTION ]"
    echo -e "OPTION:\n\t-b, --ban-weekend\n\t-g, --give-rootrights\n"
    echo -e "\t-h, --help\n\t-p, --provision\n"
}

function customize_users
{
    # Добавление новых пользователей с заданием им паролей
    for NEW_USER in "${NEW_USERS[@]}"; do
        useradd $NEW_USER
        echo "linux" | passwd $NEW_USER --stdin
    done

    groupadd $HARD_WORKERS_GROUP
    for HARD_WORKER in "${HARD_WORKERS[@]}"; do
        usermod -G $HARD_WORKERS_GROUP $HARD_WORKER
    done
}

function customize_pam_time
{
    # Назначение параметров, разделенных символом ";" :
    # - сервис, к которому применяется правило,
    # - имя терминала, к которому применяется правило,
    # - имя пользователя, для которого данное правило будет действовать,
    # - время, когда правило носит разрешающий характер.
    (
        echo 'login;tty* & !ttyp*;!admin;Wd0000-2400'
        echo 'sshd;tty* & !ttyp*;!admin;Wd0000-2400'
    ) >> /etc/security/time.conf

    # Включение модуля PAM
    sed -i '6i\account    required     pam_time.so' /etc/pam.d/login
    sed -i '8i\account    required     pam_time.so' /etc/pam.d/sshd
}


case $1 in
    -b|--ban-weekend)
        customize_users
        customize_pam_time
        echo "===================================================="
        echo "=== Access on Saturday and Sunday is prohibited! ==="
        echo "===    (except for users of the \"$HARD_WORKERS_GROUP\"-group)   ==="
        echo "===================================================="
        ;;

    -g|--give-rootrights)
        echo "Empty..."
        ;;

    -h|--help)
        print_usage
        ;;

    -p|--provision)
        # Провижининг стенда, если сценарий запущен без параметров
        cp /vagrant/script.sh /home/vagrant/
        # Разрешаем вход в систему через SSH по паролю
        sed -i '65s/PasswordAuthentication.*/PasswordAuthentication yes/g'\
            /etc/ssh/sshd_config
        systemctl restart sshd.service
        yum install -y mc nano
        ;;

    *)  print_usage
        exit 1
esac
