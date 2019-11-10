#!/usr/bin/env bash

NGINX_SRPM='nginx-1.16.1-1.el7.ngx.src.rpm'
NGINX_RPM='nginx-1.16.1-1.el7.ngx.x86-64.rpm'
OPENSSL=

cd /root/
mkdir -p ~/rpmbuild/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}

wget https://nginx.org/packages/centos/7/SRPMS/$NGINX_SRPM
rpm -i $NGINX_SRPM

wget https://www.openssl.org/source/latest.tar.gz
tar -xvf latest.tar.gz
OPENSSL=`ls |grep openssl`

yum-builddep -y rpmbuild/SPECS/nginx.spec

# Правка SPEC
sed -i '116i --with-openssl=/root/'$OPENSSL' \\' /root/rpmbuild/SPECS/nginx.spec

rpmbuild -bb rpmbuild/SPECS/nginx.spec

yum localinstall -y rpmbuild/RPMS/x86_64/$NGINX_RPM

systemctl start nginx
systemctl status nginx
