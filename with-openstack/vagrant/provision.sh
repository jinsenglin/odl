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
    PYTHON_VERSION=2.7.11-1
    PYTHON_PIP_VERSION=8.1.1-2ubuntu0.4
    PYTHON_OS_TESTR_VERSION=0.6.0-1
    [ "$APT_UPDATED" == "true" ] || apt-get update && APT_UPDATED=true
    apt-get install -y python=$PYTHON_VERSION python-pip=$PYTHON_PIP_VERSION python-os-testr=$PYTHON_OS_TESTR_VERSION
}

function download_devstack() {
    DEVSTACK_VERSION=newton
    [ -d $CACHE/devstack-$DEVSTACK_VERSION ] || \
    git clone -b stable/$DEVSTACK_VERSION -- https://github.com/openstack-dev/devstack.git $CACHE/devstack-$DEVSTACK_VERSION
}

function restore_devstack() {
    [ -f $CACHE/stack.tgz ]  && \
    tar -xpvzf $CACHE/stack.tgz -C /opt
}

function install_devstack() {
    download_devstack
    restore_devstack

    cp /vagrant/materials/local.conf $CACHE/devstack-$DEVSTACK_VERSION/local.conf
    echo "TODO: run stack.sh"
    echo "TODO: run cd /opt && tar -cpvzf $CACHE/stack.tgz stack"
}

function main() {
    :
    install_jdk
    install_odl
    install_python
    install_devstack
}
main
