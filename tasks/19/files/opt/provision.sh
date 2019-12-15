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

KEY='/home/vagrant/.ssh/id_rsa'    ; KEY_PUB=$KEY'.pub'
ENV_FILE='/etc/sysconfig/provision.env'

NAME=$1     # В процессе настроки имя меняется, поэтому используется переменная в env-файле
STAGE=$2


# Из-за необходимости промежуточной перезагрузки процесс настройки каждой ВМ
# делится на этапы ($STAGE), чтобы после перезагрузки продолжать настройку не
# с начала.
function stage_up
{
    sed -i 's/STAGE=.*/STAGE="'$(( $STAGE + 1 ))'"/' $ENV_FILE
}


case $NAME in
    $HOST_02)
        case $STAGE in
            0)  yum install -y epel-release
                yum install -y bind-utils nano
                #yum update -y

                sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
                yes | cp -rf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
                # Чтобы не вводить пароль на сервере при добавлении публичного
                # ключа с него на этот хост
                sed -i '65s/PasswordAuthentication no/PasswordAuthentication yes/g' \
                    /etc/ssh/sshd_config
                systemctl restart sshd.service

                echo $NAME'.'$DOMAIN > /etc/hostname
                echo 'PEERDNS="no"' >> /etc/sysconfig/network-scripts/ifcfg-eth0
                echo "DNS1=$HOST_00_IP" >> /etc/sysconfig/network-scripts/ifcfg-eth1

                systemctl disable provision.service
                stage_up
                reboot
                ;;
            *)  exit
                ;;
        esac
        ;;

    $HOST_01)
        case $STAGE in
            0)  yum install -y epel-release
                yum install -y bind-utils nano
                yum update -y

                sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
                yes | cp -rf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
                # Чтобы не вводить пароль на сервере при добавлении публичного
                # ключа с него на этот хост
                sed -i '65s/PasswordAuthentication no/PasswordAuthentication yes/g' \
                    /etc/ssh/sshd_config
                systemctl restart sshd.service

                echo $NAME'.'$DOMAIN > /etc/hostname
                echo 'PEERDNS="no"' >> /etc/sysconfig/network-scripts/ifcfg-eth0
                echo "DNS1=$HOST_00_IP" >> /etc/sysconfig/network-scripts/ifcfg-eth1

                stage_up
                reboot
                ;;
            1)  #systemctl stop ntpd && systemctl disable ntpd
                yum install -y ipa-server ipa-server-dns rng-tools
                systemctl start rngd && systemctl enable rngd
                ipa-server-install  \
                    --hostname=$HOST_01_FULL \
                    --domain=$HOST_01_FULL \
                    --realm=`echo $HOST_01_FULL | awk '{ print toupper($0) }'` \
                    --ds-password=12345678 \
                    --admin-password=12345678 \
                    --mkhomedir \
                    --setup-dns \
                    --forwarder=$HOST_00_IP \
                    --auto-reverse \
                    --unattended
                systemctl disable provision.service
                stage_up
                ;;
            *)  exit
                ;;
        esac
        ;;
    $HOST_00)
        case $STAGE in
            0)  # cp -r /vagrant/ansible-freeipa/ /home/vagrant/
                # chown -R vagrant:vagrant /home/vagrant/ansible-freeipa

                yum install -y epel-release
                yum install -y ansible ansible-lint bind bind-utils nano sshpass
                #yum update -y
                yes | cp -rf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
                # Запретить SSH-клиенту этой машины при подключении к хосту
                # осуществлять проверку подлинности его ключа.
                sed -i '35s/#   StrictHostKeyChecking ask/StrictHostKeyChecking no/g' \
                    /etc/ssh/ssh_config
                systemctl enable named
                echo $HOST_00_FULL > /etc/hostname
                echo 'PEERDNS="no"' >> /etc/sysconfig/network-scripts/ifcfg-eth0
                echo "DNS1=$HOST_00_IP" >> /etc/sysconfig/network-scripts/ifcfg-eth1
                stage_up
                reboot
                ;;
            1)  runuser -l vagrant -c "ssh-keygen -t rsa -N '' -b 2048 -f $KEY"
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

                stage_up
                systemctl disable provision.service
                ;;
            *)  exit
                ;;
        esac
        ;;
esac
