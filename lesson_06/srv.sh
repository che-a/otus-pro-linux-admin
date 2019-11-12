#!/usr/bin/env bash

#NGINX_DIR='/usr/share/nginx/html/repo/'

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

DOMAIN='.otus'
REPO_1='alfa.les06-repo'$DOMAIN
REPO_2='beta.les06-repo'$DOMAIN
REPOS=($REPO_1 $REPO_2)

#
# ==============================================================================
#

function sys_prepare {
    for REPO in "${REPOS[@]}"; do
        echo "127.0.0.1 $REPO" >> "/etc/hosts"
    done

    yum install -y gcc make mc nano tree wget
    yum install -y createrepo redhat-lsb-core rpmdevtools rpm-build yum-utils
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

function build_rpm_nginx {
    # Сборка nginx с поддержкой openssl

    local NGINX='nginx-1.16.1-1.el7.ngx'
    local NGINX_SRPM=$NGINX'.src.rpm'
    local NGINX_RPM=$NGINX'.x86_64.rpm'
    local NGINX_PATH_SRC='https://nginx.org/packages/centos/7/SRPMS'/$NGINX_SRPM
    local OPENSSL=
    local BASE_DIR='/root'
    local RPMBUILD_DIR=$BASE_DIR'/rpmbuild'

    # Создание дерева каталогов (rpmbuild) для сборки RPM-пакета:
    rpmdev-setuptree
    wget $NGINX_PATH_SRC -O $BASE_DIR/$NGINX_SRPM   # Скачивание SRPM-пакета nginx и
    rpm -i $BASE_DIR/$NGINX_SRPM                    # распаковка его в каталог rpmbuild

    wget https://www.openssl.org/source/latest.tar.gz -O $BASE_DIR/latest.tar.gz
    tar -xvf $BASE_DIR/latest.tar.gz -C $BASE_DIR
    OPENSSL=`ls $BASE_DIR | grep openssl`

    # Установка зависимых пакетов, которые необходимы для сборки
    yum-builddep -y $RPMBUILD_DIR/SPECS/nginx.spec

    # Правка nginx.spec
    sed -i '116i --with-openssl='$BASE_DIR/$OPENSSL' \\' $RPMBUILD_DIR/SPECS/nginx.spec

    # Сборка RPM-пакета
    rpmbuild -bb $RPMBUILD_DIR/SPECS/nginx.spec
    cp $RPMBUILD_DIR/RPMS/x86_64/$NGINX_RPM /var/www/$REPO_1/html/
}

function create_repo {

    createrepo /var/www/$REPO_1/html/
    createrepo /var/www/$REPO_2/html/
}

function  add_rpm_to_repo {
    echo "Run function add_rpm_to_repo!"
}

# ==============================================================================
sys_prepare
customize_apache
build_rpm_nginx
create_repo
# add_rpm_to_repo
