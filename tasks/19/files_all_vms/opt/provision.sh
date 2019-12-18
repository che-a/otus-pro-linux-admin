#!/usr/bin/env bash

# Сценарий для автоматизированной подготовки машин стенда с целью их дальнейшей
# оркестрации при помощи Ansible:
# - на Ansible-сервере устанавливается сервер имен;
# - с Ansible-сервера есть беспарольный доступ по SSH-ключам на каждую машину.

DOMAIN="linux.otus"
NS1='ns1'       ; NS1_FULL=$NS1'.'$DOMAIN           # Клиент Ansible
IPA='ipa'       ; IPA_FULL=$IPA'.'$DOMAIN           # Клиент Ansible
ANSIBLE='mgmt'  ; ANSIBLE_FULL=$ANSIBLE'.'$DOMAIN   # Ansible-сервер
# Машины, на которые будут добавлены публичные SSH-ключи
HOSTS_FULL=( $NS1_FULL $IPA_FULL )
#HOSTS_FULL=( $NS1_FULL )

NS1_IP="192.168.50.50"

KEY='/home/vagrant/.ssh/id_rsa'    ; KEY_PUB=$KEY'.pub'
ENV_FILE='/etc/sysconfig/provision.env'

# Из-за необходимости промежуточной перезагрузки процесс настройки каждой ВМ
# делится на этапы ($STAGE), чтобы после перезагрузки продолжать настройку не
# с начала.
STAGE=$2
function stage_up
{
    sed -i 's/STAGE=.*/STAGE="'$(( $STAGE + 1 ))'"/' $ENV_FILE
}


# В процессе настроки hostname меняется и, чтобы не было неоднозначности,
# используется переменная с именем машины в env-файле
NAME=$1
case $NAME in
    $NS1)
        case $STAGE in
            0)  cp -rf /home/vagrant/bind/* /
                yum install -y epel-release
                yum install -y bind bind-utils nano
                #yum update -y

                # Чтобы не вводить пароль на сервере при добавлении публичного
                # ключа с него на этот хост
                sed -i '65s/PasswordAuthentication no/PasswordAuthentication yes/g' \
                    /etc/ssh/sshd_config

                echo $NAME'.'$DOMAIN > /etc/hostname
                echo 'PEERDNS="no"' >> /etc/sysconfig/network-scripts/ifcfg-eth0
                echo "DNS1=$NS1_IP" >> /etc/sysconfig/network-scripts/ifcfg-eth1

                systemctl disable provision.service
                systemctl enable named.service
                stage_up
                reboot
                ;;
            *)  exit
                ;;
        esac
        ;;
    $IPA)
        case $STAGE in
            0)  yum install -y epel-release
                yum install -y bind-utils nano
                yum update -y

                sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
                # Чтобы не вводить пароль на сервере при добавлении публичного
                # ключа с него на этот хост
                sed -i '65s/PasswordAuthentication no/PasswordAuthentication yes/g' \
                    /etc/ssh/sshd_config

                echo $NAME'.'$DOMAIN > /etc/hostname
                echo 'PEERDNS="no"' >> /etc/sysconfig/network-scripts/ifcfg-eth0
                echo "DNS1=$NS1_IP" >> /etc/sysconfig/network-scripts/ifcfg-eth1

                stage_up
                reboot
                ;;
            *)  exit
                ;;
        esac
        ;;
    $ANSIBLE)
        case $STAGE in
            0)  chown -R vagrant:vagrant /home/vagrant/ansible
                yum install -y epel-release
                yum install -y ansible ansible-lint bind-utils nano sshpass
                #yum update -y
                # Запретить SSH-клиенту этой машины при подключении к хосту
                # осуществлять проверку подлинности его ключа.
                sed -i '35s/#   StrictHostKeyChecking ask/StrictHostKeyChecking no/g' \
                    /etc/ssh/ssh_config

                echo $NAME'.'$DOMAIN > /etc/hostname
                echo 'PEERDNS="no"' >> /etc/sysconfig/network-scripts/ifcfg-eth0
                echo "DNS1=$NS1_IP" >> /etc/sysconfig/network-scripts/ifcfg-eth1

                stage_up
                reboot
                ;;
            1)  runuser -l vagrant -c "ssh-keygen -t rsa -N '' -b 2048 -f $KEY"
                for HOST_FULL in ${HOSTS_FULL[@]}; do
                    # Машина, на которую необходимо скопировать публичный ключ,
                    # может быть недоступна в даный момент, поэтому производится
                    # несколько попыток.
                    for attempt in $(seq 1 100); do
                        runuser -l vagrant -c "sshpass -p vagrant ssh-copy-id -i $KEY_PUB $HOST_FULL"
                        if [ "$?" -eq 0 ]; then
                            break
                        fi
                        sleep 1
                    done
                done
                systemctl disable provision.service
                stage_up
                ;;
            *)  exit
                ;;
        esac
        ;;
esac
