#!/usr/bin/env bash

function provision
{
    echo "Stand preparation..."

    cp /vagrant/{script,test_login}.sh /home/vagrant/
    yum install -y mc
}

function ban_weekend
    # Запретить всем пользователям, кроме группы admin, логин в Сб и Вс,
    # без учета праздников
{
    local NEW_GROUP='admin'
    local NEW_USERS=('admin1' 'admin2' 'notadmin1' 'notadmin2')

    for NEW_USER in "${NEW_USERS[@]}"; do
        useradd -$NEW_USER
        echo "linux" | passwd --stdin $NEW_USER
    done

    groupadd $NEW_GROUP
    usermod -G admin vagrant    # Чтобы пользователь vagrant не потерял доступ
    useradd -G admin admin1
    useradd -G admin admin2

    sed -i "7i account     required       pam_exec.so    /usr/local/bin/test_login.sh"\
        /etc/pam.d/sshd # Добавляем необходимость проверки условия в скрипте

    # Разрешаем вход в систему через SSH по паролю
    sed -i '65s/PasswordAuthentication.*/PasswordAuthentication yes/g'\
        /etc/ssh/sshd_config
    systemctl restart sshd.service
}

provision

# Назначение параметров, разделенных символом ";" :
# - сервис, к которому применяется правило,
# - имя терминала, к которому применяется правило,
# - имя пользователя, для которого данное правило будет действовать,
# - время, когда правило носит разрешающий характер.
#(
#    echo '*;*;day;Al0800-2000'
#    echo '*;*;night;!Al0800-2000'
#    echo '*;*;friday;Fr'
#) >> /etc/security/time.conf

# Файл /etc/pam.d/sshd должен содержать эти строки
#  account    required     pam_nologin.so
#  account    required     pam_time.so
