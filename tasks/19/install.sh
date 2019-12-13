#!/usr/bin/env bash

DOMAIN='linux.otus'
REALM=`echo $DOMAIN | awk '{ print toupper($0) }'`
SERVER='ipa'
SERVER_FULL=$SERVER'.'$DOMAIN
PASSWORD='12345678'


systemctl stop ntpd
systemctl disable ntpd

yum install -y ipa-server ipa-server-dns rng-tools

systemctl start rngd
systemctl enable rngd

ipa-server-install  --hostname=$SERVER_FULL \
                    --domain=$DOMAIN \
                    --realm=$REALM \
                    --ds-password=$PASSWORD \
                    --admin-password=$PASSWORD \
                    --mkhomedir \
                    --setup-dns \
                    --forwarder=77.88.8.8 \
                    --auto-reverse \
                    --unattended
