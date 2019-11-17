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
# Копируем юнит из шаблона
cp /usr/lib/systemd/system/httpd.service /etc/systemd/system/httpd@.service
# Добавляем параметр для запуска нескольких экземпляров
sed -i '/^EnvironmentFile/ s/$/-%I/' /etc/systemd/system/httpd@.service


cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd1.conf
cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd2.conf
mv /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf.bak

sed -i 's/Listen 80/Listen 8081/' /etc/httpd/conf/httpd1.conf
sed -i 's/Listen 80/Listen 8082/' /etc/httpd/conf/httpd2.conf



#sed -i '/ServerRoot "\/etc\/httpd"/a PidFile \/var\/run\/httpd-second.pid' /etc/httpd/conf/httpd-second.conf

#systemctl disable httpd
#systemctl daemon-reload
#systemctl start httpd@first
#systemctl start httpd@second

}


function task3v2
{
    #yum install -y policycoreutils policycoreutils-python

    echo "127.0.0.1 site1.otus site2.otus site3.otus" >> "/etc/hosts"


    # Настройка главного файла конфигурации
    echo 'IncludeOptional sites-enabled/*.conf' >> "/etc/httpd/conf/httpd.conf"
    rm "/etc/httpd/conf.d/welcome.conf"

    ln -s "/etc/httpd/sites-available/site1.otus.conf" \
        "/etc/httpd/sites-enabled/site1.otus.conf"
    ln -s "/etc/httpd/sites-available/site2.otus.conf" \
        "/etc/httpd/sites-enabled/site2.otus.conf"
    ln -s "/etc/httpd/sites-available/site3.otus.conf" \
        "/etc/httpd/sites-enabled/site3.otus.conf"

    #setsebool -P httpd_unified 1
    #semanage port -a -t http_port_t -p tcp 8081
    #semanage port -a -t http_port_t -p tcp 8082
    #semanage port -a -t http_port_t -p tcp 8083

    sed -i "s/SELINUX=.*/SELINUX=permissive/" /etc/selinux/config
    reboot
    #systemctl restart httpd && systemctl enable httpd

}
yum install -y mc nano tree

task1
task2
task3v1
task3v2
