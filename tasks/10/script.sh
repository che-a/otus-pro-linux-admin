#!/usr/bin/env bash

ADMIN_GROUP='admin'
NEW_USERS=('dux' 'fix' 'gex' 'rex')
PROGNAME=`basename $0`

function print_usage {
    echo -e "\n$PROGNAME - Working with PAM"
    echo -e "Usage: $PROGNAME [ OPTION ]\n"
    echo -e "OPTION:\n\t-b, --ban-weekend\n\t-g, --give-rootrights\n"
    echo -e "\t-h, --help\n\t-p, --provision\n"
}

function customize_users
{
    local ADMIN_USER=$1 # Этот пользователь будет включен в разрешенную группу

    # Добавление новых пользователей с установкой им паролей
    for NEW_USER in "${NEW_USERS[@]}"; do
        useradd $NEW_USER
        echo "linux" | passwd $NEW_USER --stdin
    done

    groupadd $ADMIN_GROUP
    usermod -G $ADMIN_GROUP vagrant    # Чтобы пользователь vagrant не потерял доступ
    useradd -G $ADMIN_GROUP $ADMIN_USER
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
        customize_users 'rex'   # Добавляем пользователя rex в группу admin
        customize_pam_time
        echo "=== Access on Saturday and Sunday is prohibited! ==="
        echo "===    (except for users of the \"$ADMIN_GROUP\"-group)   ==="
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
