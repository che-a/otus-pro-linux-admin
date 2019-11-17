#!/usr/bin/env bash

function task1
{
    /bin/cp -rf /vagrant/include/* /
    chmod +x /opt/{generator,watcher}.sh
    touch /var/log/generator.log

    systemctl daemon-reload
    systemctl enable {generator,watcher}.timer
    systemctl start {generator,watcher}.timer
}

function task2
{
    yum install -y epel-release
    yum install -y spawn-fcgi php php-cli mod_fcgid httpd

    sed -i 's/#SOCKET/SOCKET/' /etc/sysconfig/spawn-fcgi
    sed -i 's/#OPTIONS/OPTIONS/' /etc/sysconfig/spawn-fcgi

    systemctl daemon-reload
    systemctl enable spawn-fcgi
    systemctl start spawn-fcgi
}

function task3v1
{
    echo "127.0.0.1 site1.otus site2.otus" >> "/etc/hosts"

    # Копируем юнит из шаблона
    cp /usr/lib/systemd/system/httpd.service /etc/systemd/system/httpd@.service
    # Добавляем в шаблон параметр для запуска нескольких экземпляров
    sed -i '/^EnvironmentFile/ s/$/-%I/' /etc/systemd/system/httpd@.service

    # Che
    echo 'IncludeOptional sites-enabled/*.conf' >> "/etc/httpd/conf/httpd-instance1.conf"
    echo 'IncludeOptional sites-enabled/*.conf' >> "/etc/httpd/conf/httpd-instance2.conf"



    # Создаем файлы конфигурации для каждого экземпляра веб-сервера
    cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd-instance1.conf
    cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd-instance2.conf
    mv /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf.bak

    sed -i 's/Listen 80/Listen 8081/' /etc/httpd/conf/httpd-instance1.conf
    sed -i 's/Listen 80/Listen 8082/' /etc/httpd/conf/httpd-instance2.conf

    # Che
    ln -s "/etc/httpd/sites-available/site1.otus.conf" "/etc/httpd/sites-enabled/site1.otus.conf"
    ln -s "/etc/httpd/sites-available/site2.otus.conf" "/etc/httpd/sites-enabled/site2.otus.conf"

    rm "/etc/httpd/conf.d/welcome.conf"

    sed -i "s/SELINUX=.*/SELINUX=permissive/" /etc/selinux/config
    reboot


#sed -i '/ServerRoot "\/etc\/httpd"/a PidFile \/var\/run\/httpd-second.pid' /etc/httpd/conf/httpd-second.conf

#systemctl disable httpd
#systemctl daemon-reload
#systemctl start httpd@first
#systemctl start httpd@second

}


yum install -y mc nano tree

task1
task2
task3v1
