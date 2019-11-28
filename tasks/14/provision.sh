#!/usr/bin/env bash

CLIENT_NAME='cl'
SERVER_NAME='srv'
CLIENT_IP='192.168.50.20'
KEY='/home/vagrant/.ssh/id_rsa'
KEY_PUB=$KEY'.pub'

case $HOSTNAME in
    $SERVER_NAME)
        yum install -y epel-release
        yum install -y ansible ansible-lint sshpass nano tmux
        # Возможность использования имен серверов вместо IP-адресов
        echo "$CLIENT_IP  $CLIENT_NAME" >> /etc/hosts
        # Запретить SSH-клиенту при подключении к хосту осуществлять
        # проверку подлинности его ключа.
        sed -i '35s/#   StrictHostKeyChecking ask/StrictHostKeyChecking no/g' \
            /etc/ssh/ssh_config

        # Чтобы не вводить пароль при добавлении публичного ключа
        runuser -l vagrant -c "ssh-keygen -t rsa -N '' -b 2048 -f $KEY"
        runuser -l vagrant -c "sshpass -p vagrant ssh-copy-id -i $KEY_PUB $CLIENT_NAME"

        cp -r /vagrant/ansible-bacula/ /home/vagrant/
        chown -R vagrant:vagrant /home/vagrant/ansible-bacula
        ;;

    $CLIENT_NAME)
        sed -i '65s/PasswordAuthentication no/PasswordAuthentication yes/g' \
            /etc/ssh/sshd_config
        systemctl restart sshd.service
        ;;
esac
