#!/usr/bin/env bash

SRV1='mon'
SRV2='web'
ANSIBLE_SERVER='ansible'
KEY='/home/vagrant/.ssh/id_rsa'
KEY_PUB=$KEY'.pub'

case $HOSTNAME in
    $ANSIBLE_SERVER)
        yum install -y epel-release
        yum install -y ansible ansible-lint sshpass mc nano tmux tree wget
        # Возможность использования имен серверов вместо IP-адресов
        echo "192.168.50.11  $SRV1" >> /etc/hosts
        echo "192.168.50.12  $SRV2" >> /etc/hosts
        # Запретить SSH-клиенту при подключении к хосту осуществлять
        # проверку подлинности его ключа.
        sed -i '35s/#   StrictHostKeyChecking ask/StrictHostKeyChecking no/g' \
            /etc/ssh/ssh_config

        # Чтобы не вводить пароль при добавлении публичного ключа
        runuser -l vagrant -c "ssh-keygen -t rsa -N '' -b 2048 -f $KEY"
        runuser -l vagrant -c "sshpass -p vagrant ssh-copy-id -i $KEY_PUB $SRV1"
        runuser -l vagrant -c "sshpass -p vagrant ssh-copy-id -i $KEY_PUB $SRV2"

        cp -r /vagrant/mon-prom/ /home/vagrant/
        chown -R vagrant:vagrant /home/vagrant/mon-prom
        ;;

    $SRV1|$SRV2)
        sed -i '56s/PasswordAuthentication no/PasswordAuthentication yes/g' \
            /etc/ssh/sshd_config
        systemctl restart sshd.service
        ;;
esac
