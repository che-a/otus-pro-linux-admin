#!/usr/bin/env bash

PROGNAME=`basename $0`
HARD_WORKERS_GROUP='admin'  # Группа пользователей с доступом в Сб и Вс
NEW_USERS=('dux' 'fix' 'gex' 'rex')   # Обычные пользователи, без доступа в Сб и Вс
HARD_WORKERS=('vagrant' 'rex')  # Пользователи из группы $ADMIN_GROUP и,
                                # соответственно, с доступом в Сб и Вс
PAM_EXEC_SCRIPT='/usr/local/bin/pam_exec.sh'    # Сценарий проверки принадлжености
                                                # пользователя группе $HARD_WORKERS_GROUP

# Для вывода информации при вызове программы с параметром -h|--help
function print_help
{
    echo -e "\n$PROGNAME - Working with PAM"
    echo -e "Usage: $PROGNAME [ OPTION ]"
    echo -e "OPTION:\t-b, --ban-weekend\n\t-g, --give-rootrights"
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

function customize_pam_exec
{
    # Включение модуля PAM
    sed -i '6i\account    required     pam_exec.so  '$PAM_EXEC_SCRIPT /etc/pam.d/login
    sed -i '8i\account    required     pam_exec.so  '$PAM_EXEC_SCRIPT /etc/pam.d/sshd
}


case $1 in
    -b|--ban-weekend)
        customize_users
        customize_pam_exec
        echo "===================================================="
        echo "=== Access on Saturday and Sunday is prohibited! ==="
        echo "===    (except for users of the \"$HARD_WORKERS_GROUP\"-group)   ==="
        echo "===================================================="
        ;;

    -g|--give-rootrights)
        echo "Empty..."
        ;;

    -h|--help)
        print_help
        ;;

    -p|--provision)
        # Провижининг стенда, если сценарий запущен без параметров
        cp /vagrant/script.sh /home/vagrant/
        cp /vagrant/pam_exec.sh $PAM_EXEC_SCRIPT
        # Разрешаем вход в систему через SSH по паролю
        sed -i '65s/PasswordAuthentication.*/PasswordAuthentication yes/g'\
            /etc/ssh/sshd_config
        systemctl restart sshd.service
        yum install -y mc nano
        ;;

    *)  print_help
        exit 1
esac
