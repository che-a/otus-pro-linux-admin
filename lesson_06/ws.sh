#!/usr/bin/env bash

DOMAIN='otus'
REPO_1_NAME='repo1'
REPO_2_NAME='repo2'
REPO_3_NAME='repo3'
REPO_1=$REPO_1_NAME'.'$DOMAIN
REPO_2=$REPO_2_NAME'.'$DOMAIN
REPO_3=$REPO_3_NAME'.'$DOMAIN

REPO_NAMES=($REPO_1_NAME $REPO_2_NAME $REPO_3_NAME)
REPOS=($REPO_1 $REPO_2 $REPO_3)

function sys_prepare
{
    local STR='192.168.1.10 '
    for REPO in "${REPOS[@]}"; do
        STR=$STR$REPO' '
    done
    echo $STR >> "/etc/hosts"

    yum install -y nano mc tree
}

function install_repos
{
    local COUNT=0
    for REPO in "${REPOS[@]}"; do
        (
            echo '['${REPO_NAMES[$COUNT]}']'
            echo 'name=OTUS Linux - Repo '$(( COUNT + 1 ))
            echo 'baseurl=http://'$REPO
            echo 'gpgcheck=0'
            echo 'enabled=1'
        ) > /etc/yum.repos.d/$REPO'.repo'
        COUNT=$(( COUNT + 1 ))
    done
}


sys_prepare
install_repos
