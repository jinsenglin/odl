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

function install_ovs() {
    OVS_VERSION=2.5.2-0ubuntu0.16.04.1
    [ "$APT_UPDATED" == "true" ] || apt-get update && APT_UPDATED=true
    apt-get install -y openvswitch-switch=$OVS_VERSION openvswitch-common=$OVS_VERSION
}

function download_odl() {
    ODL_VERSION=0.5.3-Boron-SR3
    [ -f $CACHE/distribution-karaf-$ODL_VERSION.tar.gz ] || \
    wget https://nexus.opendaylight.org/content/repositories/public/org/opendaylight/integration/distribution-karaf/$ODL_VERSION/distribution-karaf-$ODL_VERSION.tar.gz -O $CACHE/distribution-karaf-$ODL_VERSION.tar.gz
}

function install_odl() {
    download_odl

    tar -zxf $CACHE/distribution-karaf-$ODL_VERSION.tar.gz -C /opt
    ln -sf /opt/distribution-karaf-$ODL_VERSION /opt/odl 
}

function main() {
    :
    install_jdk
    install_ovs
    install_odl
}
main
