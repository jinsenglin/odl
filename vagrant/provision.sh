#!/bin/bash

set -e

LOG=/tmp/provision.log
date | tee $LOG            # when
whoami | tee -a $LOG       # who
pwd | tee -a $LOG          # where

function install_jdk() {
    JDK_VERSION=8
    apt-get update
    apt-get install openjdk-$JDK_VERSION-jdk
}

function download_odl() {
    ODL_VERSION=0.5.3-Boron-SR3
    wget https://nexus.opendaylight.org/content/repositories/public/org/opendaylight/integration/distribution-karaf/$ODL_VERSION/distribution-karaf-$ODL_VERSION.tar.gz
}

function main() {
    :
    install_jdk
    #download_odl
}
main
