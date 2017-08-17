#!/bin/bash

set -e

LOG=/tmp/provision.log
date | tee $LOG            # when:  Thu Aug 10 07:48:13 UTC 2017
whoami | tee -a $LOG       # who:   root
pwd | tee -a $LOG          # where: /home/ubuntu

CACHE=/vagrant/cache
[ -d $CACHE ] || mkdir -p $CACHE 

function use_local_apt_server() {
    cat > /etc/apt/sources.list <<DATA
deb http://192.168.240.3/ubuntu xenial main restricted
deb http://192.168.240.3/ubuntu xenial universe
deb http://192.168.240.3/ubuntu xenial multiverse
deb http://192.168.240.3/ubuntu xenial-updates main restricted
deb http://192.168.240.3/ubuntu xenial-updates universe
deb http://192.168.240.3/ubuntu xenial-updates multiverse
deb http://192.168.240.3/ubuntu xenial-security main restricted
deb http://192.168.240.3/ubuntu xenial-security universe
deb http://192.168.240.3/ubuntu xenial-security multiverse
deb http://192.168.240.3/ubuntu-cloud-archive xenial-updates/newton main
DATA
}

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

function main() {
    :
    #use_local_apt_server
    #install_odl
}
main
