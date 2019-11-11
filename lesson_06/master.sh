#!/usr/bin/env bash

#NGINX='nginx-1.16.1-1.el7.ngx'
#NGINX_SRPM=$NGINX'.src.rpm'
#NGINX_RPM=$NGINX'.x86_64.rpm'

#BASE_DIR='/root'
#RPMBUILD_DIR=$BASE_DIR'/rpmbuild'
#NGINX_DIR='/usr/share/nginx/html/repo/'
#OPENSSL=

#mkdir -p $RPMBUILD_DIR/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}

#wget https://nginx.org/packages/centos/7/SRPMS/$NGINX_SRPM -O $BASE_DIR/$NGINX_SRPM
#echo "=== rpm -i ==="
#rpm -i $BASE_DIR/$NGINX_SRPM

#wget https://www.openssl.org/source/latest.tar.gz
#tar -xvf $BASE_DIR/latest.tar.gz
#OPENSSL=`ls |grep openssl`

#echo '=== yum-builddep ==='
#yum-builddep -y $RPMBUILD_DIR/SPECS/nginx.spec

# Правка SPEC
#sed -i '116i --with-openssl=/root/'$OPENSSL' \\' $RPMBUILD_DIR/SPECS/nginx.spec

#rpmbuild -bb $RPMBUILD_DIR/SPECS/nginx.spec

#yum localinstall -y "$RPMBUILD_DIR/RPMS/x86_64/$NGINX_RPM" \
#    && systemctl start nginx \
#    && systemctl status nginx \
#    && systemctl enable nginx

#
# Создание своего репозитория
#

#mkdir -p $NGINX_DIR
#cp $RPMBUILD_DIR/RPMS/x86_64/$NGINX_RPM $NGINX_DIR
#wget http://www.percona.com/downloads/percona-release/redhat/0.1-6/percona-release-0.1-6.noarch.rpm \
#    -O /usr/share/nginx/html/repo/percona-release-0.1-6.noarch.rpm

#createrepo $NGINX_DIR
#sed -i '11i autoindex on;' /etc/nginx/conf.d/default.conf

#cat >> /etc/yum.repos.d/otus.repo << _EOF_
#[otus]
#name=otus-linux
#baseurl=http://master/repo
#gpgcheck=0
#enabled=1
#_EOF_

#reboot



#
# ==============================================================================
#

function sys_prepare {
    echo -e "192.168.1.200\tslave\tslave" >> /etc/hosts

    # yum install -y epel-release
    yum install -y mc nano
    #yum install -y gcc redhat-lsb-core rpmdevtools rpm-build createrepo yum-utils
}
function customize_apache {
    local CFG_DIR='/etc/httpd'
    local SA_DIR=$CFG_DIR'/sites-available'
    local SE_DIR=$CFG_DIR'/sites-enabled'
    local CONFD_DIR=$CFG_DIR'/conf.d'

    local MAIN_CFG_FILE=$CFG_DIR'/conf/httpd.conf'

    local DOC_DIR='/var/www/html'
    local REPO_1='repo.rulez.otus'
    local REPO_2='repo.trash.otus'
    local REPOS=($REPO_1 $REPO_2)

    local PORT='25000'

    # Первичные действия
    yum install -y httpd
    mkdir "{$SA_DIR,$SE_DIR}"

    # Настройка главного файла конфигурации

    echo 'IncludeOptional sites-enabled/*.conf' >> $MAIN_CFG_FILE
    sed -i 's/Listen 80/Listen '$PORT'/' $MAIN_CFG_FILE

    # Создание репозиториев
    for REPO in "${REPOS[@]}"; do
        mkdir -p "$DOC_DIR/$REPO/log/"
        # Создание файлов конфигурации виртуальных хостов
        (
            echo '<VirtualHost *:'$PORT'>'
            echo '    ServerName www.'$REPO
            echo '    ServerAlias '$REPO
            echo '    DocumentRoot '$DOC_DIR/$REPO
            echo '    ErrorLog '$DOC_DIR/$REPO'/log/error.log'
            echo '    CustomLog '$DOC_DIR/$REPO'/log/requests.log combined'
            echo '</VirtualHost>'
        ) > $SA_DIR"/"$REPO".conf"
        # Включение созданных сайтов
        ln -s "$SA_DIR/$REPO.conf" "$SE_DIR/$REPO.conf"
        chown -R www-data:www-data "$DOC_DIR/$REPO"
    done

    systemctl start httpd && systemctl enable httpd
}

function create_repo {
    echo "Run function create_repo!"
}
function  add_rpm_to_repo {
    echo "Run function add_rpm_to_repo!"
}

# ==============================================================================
sys_prepare
customize_apache
create_repo
add_rpm_to_repo
