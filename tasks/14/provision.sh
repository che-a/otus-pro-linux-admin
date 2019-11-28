#!/usr/bin/env bash

CLIENT_NAME='client1'
SERVER_NAME='srv'
CLIENT_IP='192.168.50.20'
KEY='.ssh/id_rsa'
KEY_PUB=$KEY'.pub'

case $HOSTNAME in
    $SERVER_NAME)
        yum install -y epel-release
        yum install -y ansible ansible-lint sshpass
        # Возможность использования имен серверов вместо IP-адресов
        echo "$CLIENT_IP  $CLIENT_NAME" >> /etc/hosts
        # Запретить SSH-клиенту при подключении к хосту осуществлять
        # проверку подлинности его ключа.
        sed -i '35s/#   StrictHostKeyChecking ask/StrictHostKeyChecking no/g' \
            /etc/ssh/ssh_config

        # Чтобы не вводить пароль при добавлении публичного ключа
        # - для пользователя vagrant
        runuser -l vagrant -c "ssh-keygen -t rsa -N '' -b 2048 -f /home/vagrant/$KEY"
        runuser -l vagrant -c "sshpass -p vagrant ssh-copy-id -i /home/vagrant/$KEY_PUB $CLIENT_NAME"
        # - для пользователя root
        ssh-keygen -t rsa -N '' -b 2048 -f /root/$KEY
        sshpass -p vagrant ssh-copy-id -i /root/$KEY_PUB $CLIENT_NAME

        cp -r /vagrant/ansible-bacula/ /home/vagrant/
        chown -R vagrant:vagrant /home/vagrant/ansible-bacula
        ;;

    $CLIENT_NAME)
        sed -i '65s/PasswordAuthentication no/PasswordAuthentication yes/g' \
            /etc/ssh/sshd_config
        systemctl restart sshd.service
        ;;
esac
