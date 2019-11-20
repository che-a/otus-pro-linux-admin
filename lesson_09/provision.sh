#!/usr/bin/env bash


case $HOSTNAME in
    ansible)    yum install -y sshpass mc nano #tmux tree
                echo "192.168.1.21  srv1" >> /etc/hosts
                echo "192.168.1.22  srv2" >> /etc/hosts
                sed -i '35s/#   StrictHostKeyChecking ask/StrictHostKeyChecking no/g' \
                    /etc/ssh/ssh_config
                systemctl restart sshd

                runuser -l vagrant -c 'ssh-keygen -t rsa -N "" -b 2048 -f "/home/vagrant/.ssh/id_rsa"'
                runuser -l vagrant -c 'sshpass -p "vagrant" ssh-copy-id -i "/home/vagrant/.ssh/id_rsa.pub" srv1'
                runuser -l vagrant -c 'sshpass -p "vagrant" ssh-copy-id -i "/home/vagrant/.ssh/id_rsa.pub" srv2'
                ;;

    srv1)       sed -i '65s/PasswordAuthentication no/PasswordAuthentication yes/g' \
                    /etc/ssh/sshd_config
                systemctl restart sshd.service
                ;;

    srv2)       sed -i '123s/PasswordAuthentication no/PasswordAuthentication yes/g' \
                    /etc/ssh/sshd_config
                systemctl restart sshd.service
                ;;
esac
