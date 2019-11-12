#!/usr/bin/env bash

DOMAIN='.otus'
REPO_1='alfa.les06-repo'$DOMAIN
REPO_2='beta.les06-repo'$DOMAIN
REPOS=($REPO_1 $REPO_2)

function sys_prepare {
    for REPO in "${REPOS[@]}"; do
        echo "192.168.1.10 $REPO" >> "/etc/hosts"
    done
    echo '192.168.1.10 srv.otus' >> /etc/hosts

    yum install -y nano mc tree
}

function install_repo {
    (
        echo '[alfa]'
        echo 'name='$REPO_1
        echo 'baseurl='$REPO_1
        echo 'gpgcheck=0'
        echo 'enabled=1'
    ) > /etc/yum.repos.d/$REPO_1
    (
        echo '[beta]'
        echo 'name='$REPO_2
        echo 'baseurl='$REPO_2
        echo 'gpgcheck=0'
        echo 'enabled=1'
    ) > /etc/yum.repos.d/$REPO_2

}


sys_prepare
install_repo
