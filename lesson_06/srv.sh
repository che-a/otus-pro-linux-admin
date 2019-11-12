#!/usr/bin/env bash

#BASE_DIR='/root'
#RPMBUILD_DIR=$BASE_DIR'/rpmbuild'
#NGINX_DIR='/usr/share/nginx/html/repo/'



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

DOMAIN='.otus'
REPO_1='rulez.les06-repo'$DOMAIN
REPO_2='trash.les06-repo'$DOMAIN
REPOS=($REPO_1 $REPO_2)

#
# ==============================================================================
#

function sys_prepare {
#    for REPO in "${REPOS[@]}"; do
#        echo "127.0.0.1 $REPO" >> /etc/hosts
#    done

    yum install -y mc nano wget
    yum install -y createrepo rpmdevtools rpm-build
    #yum install -y gcc redhat-lsb-core  yum-utils
}

function customize_apache {
    local CFG_DIR='/etc/httpd'
    local SA_DIR=$CFG_DIR'/sites-available'
    local SE_DIR=$CFG_DIR'/sites-enabled'
    local CONFD_DIR=$CFG_DIR'/conf.d'
    local MAIN_CFG_FILE=$CFG_DIR'/conf/httpd.conf'
    local DOC_DIR='/var/www'
    local PORT='80'

    yum install -y httpd
    mkdir $SA_DIR $SE_DIR

    # Настройка главного файла конфигурации
    echo 'IncludeOptional sites-enabled/*.conf' >> $MAIN_CFG_FILE
    #sed -i 's/Listen 80/Listen '$PORT'/' $MAIN_CFG_FILE
    rm $CONFD_DIR"/welcome.conf"

    # Создание репозиториев
    for REPO in "${REPOS[@]}"; do
        mkdir -p "$DOC_DIR/$REPO/"{html,log}
        echo "REPOSITORY: $REPO" > "$DOC_DIR/$REPO/html/header.html"

        # Создание файлов конфигурации виртуальных хостов
        (
            echo '<VirtualHost *:'$PORT'>'
            echo '    ServerName www.'$REPO
            echo '    ServerAlias '$REPO
            echo "    DocumentRoot $DOC_DIR/$REPO/html"
            echo "    <Directory $DOC_DIR/$REPO/html>"
            echo '        Options Indexes Includes FollowSymLinks'
            echo '        IndexOptions FancyIndexing FoldersFirst IconsAreLinks NameWidth=60'
            echo '        IndexIgnore header.html'
            echo '        HeaderName header.html'
            echo '    </Directory>'
            echo "    ErrorLog $DOC_DIR/$REPO/log/error.log"
            echo "    CustomLog $DOC_DIR/$REPO/log/requests.log combined"
            echo '</VirtualHost>'
        ) > $SA_DIR"/"$REPO".conf"
        # Включение созданных репозиториев
        ln -s "$SA_DIR/$REPO.conf" "$SE_DIR/$REPO.conf"
        chown -R vagrant:vagrant "$DOC_DIR/$REPO/html"
        chmod -R 755 $DOC_DIR
    done

    setsebool -P httpd_unified 1
    systemctl start httpd && systemctl enable httpd
}

function create_repo {
    echo "Run function create_repo!"
}

function build_rpm_nginx {
    # Сборка nginx с поддержкой openssl

    local NGINX='nginx-1.16.1-1.el7.ngx'
    local NGINX_SRPM=$NGINX'.src.rpm'
    local NGINX_RPM=$NGINX'.x86_64.rpm'
    local NGINX_PATH_SRC='https://nginx.org/packages/centos/7/SRPMS'/$NGINX_SRPM
    local OPENSSL=

    # Создание дерева каталогов (rpmbuild) для сборки RPM-пакета:
    rpmdev-setuptree
    wget $NGINX_PATH_SRC    # Скачивание SRPM-пакета nginx и
    rpm -i $NGINX_SRPM      # распаковка его в каталог rpmbuild

    wget https://www.openssl.org/source/latest.tar.gz
    tar -xvf latest.tar.gz
    OPENSSL=`ls | grep openssl`

    # Установка зависимых пакетов, которые необходимы для сборки
    yum-builddep -y rpmbuild/SPECS/nginx.spec

    # Правка nginx.spec
    sed -i '116i --with-openssl=/root/'$OPENSSL' \\' rpmbuild/SPECS/nginx.spec

    # Сборка RPM-пакета
    rpmbuild -bb rpmbuild/SPECS/nginx.spec
}

function  add_rpm_to_repo {
    echo "Run function add_rpm_to_repo!"
}

# ==============================================================================
sys_prepare
customize_apache
create_repo
build_rpm_nginx
add_rpm_to_repo
