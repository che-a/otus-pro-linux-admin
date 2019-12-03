#!/usr/bin/env bash

SRV2='web'
SRV1='elk'
ANSIBLE_SERVER='log'
SRV2_IP='192.168.50.30'
SRV1_IP='192.168.50.20'
KEY='/home/vagrant/.ssh/id_rsa'
KEY_PUB=$KEY'.pub'

case $HOSTNAME in
    $ANSIBLE_SERVER)
        yum install -y epel-release
        yum install -y ansible ansible-lint nano sshpass tmux
        # Возможность использования имен серверов вместо IP-адресов
        echo "$SRV2_IP  $SRV2" >> /etc/hosts
        echo "$SRV1_IP  $SRV1" >> /etc/hosts
        # Запретить SSH-клиенту при подключении к хосту осуществлять
        # проверку подлинности его ключа.
        sed -i '35s/#   StrictHostKeyChecking ask/StrictHostKeyChecking no/g' \
            /etc/ssh/ssh_config

        # Чтобы не вводить пароль при добавлении публичного ключа
        runuser -l vagrant -c "ssh-keygen -t rsa -N '' -b 2048 -f $KEY"
        runuser -l vagrant -c "sshpass -p vagrant ssh-copy-id -i $KEY_PUB $SRV2"
        runuser -l vagrant -c "sshpass -p vagrant ssh-copy-id -i $KEY_PUB $SRV1"

        cp -r /vagrant/ansible-log/ /home/vagrant/
        chown -R vagrant:vagrant /home/vagrant/ansible-log
        ;;

    $SRV2|$SRV1)
        sed -i '65s/PasswordAuthentication no/PasswordAuthentication yes/g' \
            /etc/ssh/sshd_config
        systemctl restart sshd.service
        ;;
esac

yes | cp -rf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
reboot
