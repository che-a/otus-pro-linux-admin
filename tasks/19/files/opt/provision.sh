#!/usr/bin/env bash

# Сценарий для автоматизированной подготовки машин стенда с целью их дальнейшей
# оркестрации при помощи Ansible:
# - на Ansible-сервере устанавливается сервер имен;
# - с Ansible-сервера есть беспарольный доступ по SSH-ключам на каждую машину.

DOMAIN='linux.otus'
HOST_02='gw'    ; HOST_02_FULL=$HOST_02'.'$DOMAIN   # Ansible-клиент
HOST_01='ipa'   ; HOST_01_FULL=$HOST_01'.'$DOMAIN   # Ansible-клиент
HOST_00='ns1'   ; HOST_00_FULL=$HOST_00'.'$DOMAIN   # Ansible-сервер

# Машины, на которые будут добавлены публичные SSH-ключи
HOSTS_FULL=( $HOST_02_FULL $HOST_01_FULL )
HOST_00_IP='192.168.50.50'

KEY1='/root/.ssh/id_rsa'            ; KEY1_PUB=$KEY1'.pub'
KEY2='/home/vagrant/.ssh/id_rsa'    ; KEY2_PUB=$KEY2'.pub'

# Из-за необходимости промежуточной перезагрузки процесс настройки каждой ВМ
# делится на этапы ($STAGE), чтобы после перезагрузки продолжать настройку не
# с начала.
STAGE=$1
function stage_up
{
    local NEW_STAGE=$(( $STAGE + 1 ))
    echo "STAGE=$NEW_STAGE" > /etc/sysconfig/provision
}

case $HOSTNAME in
    $HOST_02 | $HOST_01)
        case $STAGE in
            0)
                yum install -y epel-release
                yum install -y bind-utils nano
                yum update -y
                # Чтобы не вводить пароль при добавлении публичного ключа
                sed -i '65s/PasswordAuthentication no/PasswordAuthentication yes/g' \
                    /etc/ssh/sshd_config

                echo $HOSTNAME'.'$DOMAIN > /etc/hostname
                echo 'PEERDNS="no"' >> /etc/sysconfig/network-scripts/ifcfg-eth0
                echo "DNS1=$HOST_00_IP" >> /etc/sysconfig/network-scripts/ifcfg-eth1

                stage_up
                reboot
                ;;
            1)
                systemctl disable provision.service
                systemctl stop provision.service
                ;;
        esac
        ;;
    $HOST_00)
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
                systemctl enable named

                # Запретить SSH-клиенту при подключении к хосту осуществлять
                # проверку подлинности его ключа.
                sed -i '35s/#   StrictHostKeyChecking ask/StrictHostKeyChecking no/g' \
                    /etc/ssh/ssh_config

                echo "$HOST_00_FULL" > /etc/hostname
                echo 'PEERDNS="no"' >> /etc/sysconfig/network-scripts/ifcfg-eth0
                echo "DNS1=$HOST_00_IP" >> /etc/sysconfig/network-scripts/ifcfg-eth1
                stage_up
                reboot
                ;;
            2)
                ssh-keygen -t rsa -N '' -b 2048 -f $KEY1
                runuser -l vagrant -c "ssh-keygen -t rsa -N '' -b 2048 -f $KEY2"
                for HOST_FULL in ${HOSTS_FULL[@]}; do
                    sshpass -p vagrant ssh-copy-id -i $KEY1_PUB $HOST_FULL
                    runuser -l vagrant -c "sshpass -p vagrant ssh-copy-id -i $KEY2_PUB $HOST_FULL"
                done
                stage_up
                systemctl disable provision.service
                systemctl stop provision.service
                ;;
            3)
                ;;
        esac
        ;;
        # cp -r /vagrant/ansible-log/ /home/vagrant/
        # chown -R vagrant:vagrant /home/vagrant/ansible-log
esac
