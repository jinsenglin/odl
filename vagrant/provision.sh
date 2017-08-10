#!/bin/bash

set -e

LOG=/tmp/provision.log
date | tee $LOG            # when
whoami | tee -a $LOG       # who
pwd | tee -a $LOG          # where

function install_jdk() {
    JDK_VERSION=8
    apt-get update
    apt-get install -y openjdk-$JDK_VERSION-jdk
}

function install_ovs() {
    OVS_VERSION=2.5.2-0ubuntu0.16.04.1
    apt-get install -y openvswitch-switch=$OVS_VERSION openvswitch-common=$OVS_VERSION
}

function download_odl() {
    ODL_VERSION=0.5.3-Boron-SR3
    wget https://nexus.opendaylight.org/content/repositories/public/org/opendaylight/integration/distribution-karaf/$ODL_VERSION/distribution-karaf-$ODL_VERSION.tar.gz
}

function main() {
    :
    install_jdk
    #install_ovs
    #download_odl
}
main
