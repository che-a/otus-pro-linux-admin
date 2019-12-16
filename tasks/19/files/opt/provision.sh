#!/usr/bin/env bash

# Сценарий для автоматизированной подготовки машин стенда с целью их дальнейшей
# оркестрации при помощи Ansible:
# - на Ansible-сервере устанавливается сервер имен;
# - с Ansible-сервера есть беспарольный доступ по SSH-ключам на каждую машину.

NAME=$2     # В процессе настроки имя меняется, поэтому используется переменная в env-файле

DOMAIN="linux.otus"
NS1='ns1'    ; HOST_4_FULL=$HOST_4'.'$DOMAIN   # Клиент Ansible
HOST3='gw'    ; HOST3_FULL=$HOST3'.'$DOMAIN   # Клиент Ansible
HOST2='dhcp'  ; HOST2_FULL=$HOST2'.'$DOMAIN   # Клиент Ansible
HOST1='ipa'   ; HOST1_FULL=$HOST1'.'$DOMAIN   # Клиент Ansible
ANSIBLE='mgmt'  ; ANSIBLE_FULL=$ANSIBLE'.'$DOMAIN   # Ansible-сервер

# Машины, на которые будут добавлены публичные SSH-ключи
HOSTS_FULL=( $HOST_4_FULL $HOST_3_FULL $HOST_2_FULL $HOST_1_FULL )

NS1_IP="192.168.50.50"

KEY='/home/vagrant/.ssh/id_rsa'    ; KEY_PUB=$KEY'.pub'

case $NAME in
    $HOST_02)
        sed -i '65s/PasswordAuthentication no/PasswordAuthentication yes/g' \
            /etc/ssh/sshd_config
        systemctl restart sshd

        echo $NAME'.'$DOMAIN > /etc/hostname
        echo 'PEERDNS="no"' >> /etc/sysconfig/network-scripts/ifcfg-eth0
        echo "DNS1=$HOST_00_IP" >> /etc/sysconfig/network-scripts/ifcfg-eth1

        systemctl disable provision.service
        reboot
        ;;
    $HOST_00)
        # cp -r /vagrant/ansible-freeipa/ /home/vagrant/
        # chown -R vagrant:vagrant /home/vagrant/ansible-freeipa
        yum install -y epel-release
        yum install -y ansible ansible-lint
        # Запретить SSH-клиенту этой машины при подключении к хосту
        # осуществлять проверку подлинности его ключа.
        sed -i '35s/#   StrictHostKeyChecking ask/StrictHostKeyChecking no/g' \
            /etc/ssh/ssh_config
        systemctl restart sshd
        echo $HOST_00_FULL > /etc/hostname
        echo 'PEERDNS="no"' >> /etc/sysconfig/network-scripts/ifcfg-eth0
        echo "DNS1=$HOST_00_IP" >> /etc/sysconfig/network-scripts/ifcfg-eth1

        runuser -l vagrant -c "ssh-keygen -t rsa -N '' -b 2048 -f $KEY"
        for HOST_FULL in ${HOSTS_FULL[@]}; do
            # Машина, на которую необходимо скопировать публичный ключ
            # может быть недоступна, поэтому необходимо пробовать пока
            # не получится.
            while [ 1 ]; do
                runuser -l vagrant -c "sshpass -p vagrant ssh-copy-id -i $KEY_PUB $HOST_FULL"
                if [ "$?" -eq 0 ]; then
                    break
                fi
            done
        done
        systemctl disable provision.service
        ;;
esac
