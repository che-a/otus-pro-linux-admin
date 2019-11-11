#!/usr/bin/env bash

NGINX='nginx-1.16.1-1.el7.ngx'
NGINX_SRPM=$NGINX'.src.rpm'
NGINX_RPM=$NGINX'.x86_64.rpm'

BASE_DIR='/root'
RPMBUILD_DIR=$BASE_DIR'/rpmbuild'
NGINX_DIR='/usr/share/nginx/html/repo/'
OPENSSL=

mkdir -p $RPMBUILD_DIR/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}

wget https://nginx.org/packages/centos/7/SRPMS/$NGINX_SRPM -O $BASE_DIR/$NGINX_SRPM
echo "=== rpm -i ==="
rpm -i $BASE_DIR/$NGINX_SRPM

wget https://www.openssl.org/source/latest.tar.gz
tar -xvf $BASE_DIR/latest.tar.gz
OPENSSL=`ls |grep openssl`

echo '=== yum-builddep ==='
yum-builddep -y $RPMBUILD_DIR/SPECS/nginx.spec

# Правка SPEC
sed -i '116i --with-openssl=/root/'$OPENSSL' \\' $RPMBUILD_DIR/SPECS/nginx.spec

rpmbuild -bb $RPMBUILD_DIR/SPECS/nginx.spec

yum localinstall -y "$RPMBUILD_DIR/RPMS/x86_64/$NGINX_RPM" \
    && systemctl start nginx \
    && systemctl status nginx \
    && systemctl enable nginx

#
# Создание своего репозитория
#

mkdir -p $NGINX_DIR
cp $RPMBUILD_DIR/RPMS/x86_64/$NGINX_RPM $NGINX_DIR
wget http://www.percona.com/downloads/percona-release/redhat/0.1-6/percona-release-0.1-6.noarch.rpm \
    -O /usr/share/nginx/html/repo/percona-release-0.1-6.noarch.rpm

createrepo $NGINX_DIR
sed -i '11i autoindex on;' /etc/nginx/conf.d/default.conf

cat >> /etc/yum.repos.d/otus.repo << _EOF_
[otus]
name=otus-linux
baseurl=http://master/repo
gpgcheck=0
enabled=1
_EOF_

reboot
