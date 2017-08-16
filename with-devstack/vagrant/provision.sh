#!/bin/bash

set -e

LOG=/tmp/provision.log
date | tee $LOG            # when:  Thu Aug 10 07:48:13 UTC 2017
whoami | tee -a $LOG       # who:   root
pwd | tee -a $LOG          # where: /home/ubuntu

CACHE=/vagrant/cache
[ -d $CACHE ] || mkdir -p $CACHE 

function install_jdk() {
    JDK_VERSION=8
    [ "$APT_UPDATED" == "true" ] || apt-get update && APT_UPDATED=true
    apt-get install -y openjdk-$JDK_VERSION-jdk
}

function download_odl() {
    ODL_VERSION=0.5.3-Boron-SR3
    [ -f $CACHE/distribution-karaf-$ODL_VERSION.tar.gz ] || \
    wget -q https://nexus.opendaylight.org/content/repositories/public/org/opendaylight/integration/distribution-karaf/$ODL_VERSION/distribution-karaf-$ODL_VERSION.tar.gz -O $CACHE/distribution-karaf-$ODL_VERSION.tar.gz
}

function install_odl() {
    download_odl

    tar -zxf $CACHE/distribution-karaf-$ODL_VERSION.tar.gz -C /opt
    ln -sf /opt/distribution-karaf-$ODL_VERSION /opt/odl 
}

function install_python() {
    PYTHON_VERSION=2.7.12
    PYTHON_PIP_VERSION=2.7.12
    PYTHON_OS_TESTR_VERSION=2.7.12
    [ "$APT_UPDATED" == "true" ] || apt-get update && APT_UPDATED=true
    apt-get install -y python python-pip python-os-testr
}

function download_devstack() {
    DEVSTACK_VERSION=newton
    [ -d $CACHE/devstack-$DEVSTACK_VERSION ] || \
    git clone -b stable/$DEVSTACK_VERSION -- https://github.com/openstack-dev/devstack.git $CACHE/devstack-$DEVSTACK_VERSION
}

function install_devstack() {
    download_devstack

    echo TODO
}

function main() {
    :
    install_jdk
    install_odl
    install_python
    install_devstack
}
main