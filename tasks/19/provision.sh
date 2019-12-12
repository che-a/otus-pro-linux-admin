#!/usr/bin/env bash

DOMAIN='linux.otus'
NET='192.168.50'

CLIENT='client'
CLIENT_FULL=$CLIENT'.'$DOMAIN
CLIENT_IP=$NET'.20'
SERVER='ipa'
SERVER_FULL=$SERVER'.'$DOMAIN
SERVER_IP=$NET'.10'

KEY='/home/vagrant/.ssh/id_rsa'
KEY_PUB=$KEY'.pub'


case $HOSTNAME in
    'server')
        yum update -y
        yum install -y epel-release
        yum install -y ansible ansible-lint bind-utils nano sshpass

        # Возможность использования имен серверов вместо IP-адресов
        echo $SERVER_FULL > /etc/hostname
        echo "$SERVER_IP  $SERVER_FULL $SERVER" >> /etc/hosts
        echo "$CLIENT_IP  $CLIENT_FULL $CLIENT" >> /etc/hosts
        # Запретить SSH-клиенту при подключении к хосту осуществлять
        # проверку подлинности его ключа.
        sed -i '35s/#   StrictHostKeyChecking ask/StrictHostKeyChecking no/g' \
            /etc/ssh/ssh_config

        # Чтобы не вводить пароль при добавлении публичного ключа
        runuser -l vagrant -c "ssh-keygen -t rsa -N '' -b 2048 -f $KEY"
        runuser -l vagrant -c "sshpass -p vagrant ssh-copy-id -i $KEY_PUB $CLIENT"

        # cp -r /vagrant/ansible-log/ /home/vagrant/
        # chown -R vagrant:vagrant /home/vagrant/ansible-log
        cp /vagrant/install.sh /home/vagrant
        ;;

    'client')
        echo "$CLIENT_FULL" > /etc/hostname
        echo "$SERVER_IP  $SERVER_FULL $SERVER" >> /etc/hosts
        echo "$CLIENT_IP  $CLIENT_FULL $CLIENT" >> /etc/hosts
        sed -i '65s/PasswordAuthentication no/PasswordAuthentication yes/g' \
            /etc/ssh/sshd_config
        systemctl restart sshd.service
        # yum update -y
        # yum install -y ipa-client nano
        ;;
esac

yes | cp -rf /usr/share/zoneinfo/Europe/Moscow /etc/localtime

sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
reboot
