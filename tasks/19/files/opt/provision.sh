#!/usr/bin/env bash

# Description:
# ...
#

DOMAIN='linux.otus'
NET='192.168.50'

HOST_02='gw'
HOST_01='ipa'
SERVER='ns1'
HOST_02_IP=$NET'.1'
HOST_01_IP=$NET'.10'
SERVER_IP=$NET'.20'

HOST_02_FULL=$HOST_02'.'$DOMAIN
HOST_01_FULL=$HOST_01'.'$DOMAIN
SERVER_FULL=$SERVER'.'$DOMAIN

KEY='/home/vagrant/.ssh/id_rsa'
KEY_PUB=$KEY'.pub'

STAGE=$1


function stage_up
{
    local NEW_STAGE=$(( $STAGE + 1 ))
    echo "STAGE=$NEW_STAGE" > /etc/sysconfig/provision
}

case $HOSTNAME in
    $SERVER)
        case $STAGE in
            0)
                yum install -y epel-release
                yum install -y ansible ansible-lint nano sshpass
                yum update -y

                sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
                yes | cp -rf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
                stage_up
                reboot
                ;;
            1)
                yum install -y bind bind-utils
                chmod 755 /etc/named

                # named-checkzone linux.otus /etc/named/zones/db.linux.otus
                # named-checkzone 50.168.192.in-addr.arpa /etc/named/zones/db.192.168.50
                #systemctl start named
                systemctl enable named
                # Запретить SSH-клиенту при подключении к хосту осуществлять
                # проверку подлинности его ключа.
                sed -i '35s/#   StrictHostKeyChecking ask/StrictHostKeyChecking no/g' \
                    /etc/ssh/ssh_config

                echo "$SERVER_FULL" > /etc/hostname
                echo 'PEERDNS="no"' >> /etc/sysconfig/network-scripts/ifcfg-eth0
                echo "DNS1=$SERVER_IP" >> /etc/sysconfig/network-scripts/ifcfg-eth1
                stage_up
                reboot
                ;;
            2)
                systemctl disable provision.service
                systemctl stop provision.service
                ;;
        esac


        # Чтобы не вводить пароль при добавлении публичного ключа
#        runuser -l vagrant -c "ssh-keygen -t rsa -N '' -b 2048 -f $KEY"
#        runuser -l vagrant -c "sshpass -p vagrant ssh-copy-id -i $KEY_PUB $CLIENT"

        # cp -r /vagrant/ansible-log/ /home/vagrant/
        # chown -R vagrant:vagrant /home/vagrant/ansible-log
        ;;

    $HOST_02)
        yum install -y bind-utils nano
        echo "$HOST_02_FULL" > /etc/hostname
        echo 'PEERDNS="no"' >> /etc/sysconfig/network-scripts/ifcfg-eth0
        echo "DNS1=$SERVER_IP" >> /etc/sysconfig/network-scripts/ifcfg-eth1
#        sed -i '65s/PasswordAuthentication no/PasswordAuthentication yes/g' \
#            /etc/ssh/sshd_config
#        systemctl restart sshd.service
        reboot
        ;;

    $HOST_01)
        yum install -y bind-utils nano
        echo "$HOST_01_FULL" > /etc/hostname
        echo 'PEERDNS="no"' >> /etc/sysconfig/network-scripts/ifcfg-eth0
        echo "DNS1=$SERVER_IP" >> /etc/sysconfig/network-scripts/ifcfg-eth1
#        sed -i '65s/PasswordAuthentication no/PasswordAuthentication yes/g' \
#            /etc/ssh/sshd_config
#        systemctl restart sshd.service
        reboot
        ;;

esac
