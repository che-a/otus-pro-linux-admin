#!/usr/bin/env bash

function provision
{
    echo "Stand preparation..."

    cp /vagrant/script.sh /home/vagrant/
    yum install -y mc

}

function ban_weekend
    # Запретить всем пользователям, кроме группы admin, логин в Сб и Вс,
    # без учета праздников
{
    local NEW_GROUP='admin'
    local NEW_USERS=('admin1' 'admin2' 'notadmin1' 'notadmin2')

    groupadd $NEW_GROUP
    usermod -G admin vagrant    # Чтобы пользователь vagrant не потерял доступ

    for NEW_USER in "${NEW_USERS[@]}"; do
        useradd -$NEW_USER
        echo "linux" | passwd --stdin $NEW_USER
    done




}

# Разрешаем вход в систему через SSH по паролю
sed -i '65s/PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config
systemctl restart sshd.service

# Назначение параметров, разделенных символом ";" :
# - сервис, к которому применяется правило,
# - имя терминала, к которому применяется правило,
# - имя пользователя, для которого данное правило будет действовать,
# - время, когда правило носит разрешающий характер.
(
    echo '*;*;day;Al0800-2000'
    echo '*;*;night;!Al0800-2000'
    echo '*;*;friday;Fr'
) >> /etc/security/time.conf

# Файл /etc/pam.d/sshd должен содержать эти строки
#  account    required     pam_nologin.so
#  account    required     pam_time.so


sed -i "7i account     required       pam_exec.so    /etc/pam.sh" /etc/pam.d/sshd # Добавляем необходимость проверки условия в скрипте

useradd -G admin didaktik
echo 0000 | passwd didaktik --stdin # Задаем пароли
useradd speccy
echo 0000 | passwd speccy --stdin
#curl -o /root/.vimrc https://raw.githubusercontent.com/didaktikm/vimconf/master/.vimrc
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config  # Разрешаем вход по паролю
systemctl restart sshd
