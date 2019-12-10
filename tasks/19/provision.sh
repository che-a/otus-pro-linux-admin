#!/usr/bin/env bash

SRV1='client.linux.otus'
SRV1_IP='192.168.50.20'
ANSIBLE_SERVER='ipa-srv.linux.otus'
ANSIBLE_SERVER_IP='192.168.50.10'
KEY='/home/vagrant/.ssh/id_rsa'
KEY_PUB=$KEY'.pub'

case $HOSTNAME in
    $ANSIBLE_SERVER)
        yum update -y
        yum install -y epel-release
        yum install -y ansible ansible-lint nano sshpass tmux
        yum install -y ipa-server ipa-server-dns
        # Возможность использования имен серверов вместо IP-адресов
        echo "$SRV1_IP  $SRV1 client" >> /etc/hosts
        echo "$ANSIBLE_SERVER_IP  $ANSIBLE_SERVER ipa-srv" >> /etc/hosts

        sed -i '1s/'$ANSIBLE_SERVER'/ /g' /etc/hosts
        # Запретить SSH-клиенту при подключении к хосту осуществлять
        # проверку подлинности его ключа.
        sed -i '35s/#   StrictHostKeyChecking ask/StrictHostKeyChecking no/g' \
            /etc/ssh/ssh_config

        # Чтобы не вводить пароль при добавлении публичного ключа
        runuser -l vagrant -c "ssh-keygen -t rsa -N '' -b 2048 -f $KEY"
        runuser -l vagrant -c "sshpass -p vagrant ssh-copy-id -i $KEY_PUB $SRV1"
        #cp -r /vagrant/ansible-log/ /home/vagrant/
        #chown -R vagrant:vagrant /home/vagrant/ansible-log

        # Запускаем установку FreeIPA Server в режиме автоответа, передав необходимые параметры:
        # -a password    #пароль учетной записи admin
        # --hostname=ipaserver.test.lab   #FQDN имя сервера
        # -r TEST.LAB  #Kerberos realm name (доменное имя большими буквами)
        # -p password  #The kerberos master password
        # -n test.lab  #доменное имя
        # -U  #установка в режиме автоответа
        #ipa-server-install -a password --hostname=ipaserver.test.lab -r TEST.LAB -p password -n test.lab -U
#        ipa-server-install -a password --hostname=$ANSIBLE_SERVER -r LINUX.OTUS -p password -n linux.otus -U
        ;;

    $SRV1)
        sed -i '65s/PasswordAuthentication no/PasswordAuthentication yes/g' \
            /etc/ssh/sshd_config
        systemctl restart sshd.service
        ;;
esac

yes | cp -rf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
#reboot
