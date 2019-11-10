#!/usr/bin/env bash

NGINX_SRPM='nginx-1.16.1-1.el7.ngx.src.rpm'
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
