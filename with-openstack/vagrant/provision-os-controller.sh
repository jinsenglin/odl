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

function each_node_must_resolve_the_other_nodes_by_name_in_addition_to_IP_address() {
    cat >> /etc/hosts <<DATA
172.18.161.101 os-controller
172.18.161.102 os-network
172.18.161.103 os-compute
172.18.161.104 odl-controller
DATA

    # Reference https://docs.openstack.org/newton/install-guide-ubuntu/environment-networking.html
}

function install_python() {
    PYTHON_VERSION=2.7.11-1
    PYTHON_PIP_VERSION=8.1.1-2ubuntu0.4
    [ "$APT_UPDATED" == "true" ] || apt-get update && APT_UPDATED=true
    apt-get install -y python=$PYTHON_VERSION python-pip=$PYTHON_PIP_VERSION
}

function install_ntp() {
    CHRONY_VERSION=
    [ "$APT_UPDATED" == "true" ] || apt-get update && APT_UPDATED=true
    apt-get install -y chrony #TODO get version

    # TODO
    # Edit the /etc/chrony/chrony.conf file
    # To enable other nodes to connect
    # Restart the NTP service

    # Reference https://docs.openstack.org/newton/install-guide-ubuntu/environment-ntp-controller.html
}

function install_sqldb() {
    MARIADB_SERVER_VERSION=
    PYTHON_PYMSQL_VERSION=
    [ "$APT_UPDATED" == "true" ] || apt-get update && APT_UPDATED=true
    apt-get install -y mariadb-server python-pymysql #TODO get version

    # TODO
    # Create and edit the /etc/mysql/mariadb.conf.d/99-openstack.cnf file
    # Restart the database service
    # Secure the database service by running the mysql_secure_installation script

    # Reference https://docs.openstack.org/newton/install-guide-ubuntu/environment-sql-database.html
}

function install_mq() {
    RABBITMQ_SERVER_VERSION=
    [ "$APT_UPDATED" == "true" ] || apt-get update && APT_UPDATED=true
    apt-get install -y rabbitmq-server #TODO get version

    # TODO
    # Add the openstack user
    # Permit configuration

    # Reference https://docs.openstack.org/newton/install-guide-ubuntu/environment-messaging.html
}

function install_memcached() {
    MEMCACHED_VERSION=
    PYTHON_MEMCACHE_VERSION=
    [ "$APT_UPDATED" == "true" ] || apt-get update && APT_UPDATED=true
    apt-get install -y memcached python-memcache #TODO get version

    # TODO
    # Edit the /etc/memcached.conf file
    # Restart the Memcached service

    # Reference https://docs.openstack.org/newton/install-guide-ubuntu/environment-memcached.html
}

function install_keystone() {
    :
    # Reference https://docs.openstack.org/newton/install-guide-ubuntu/keystone.html
}

function install_glance() {
    :
    # Reference https://docs.openstack.org/newton/install-guide-ubuntu/glance.html
}

function install_neutron() {
    :
    # Reference https://docs.openstack.org/newton/install-guide-ubuntu/neutron.html
}

function install_nova() {
    :
    # Reference https://docs.openstack.org/newton/install-guide-ubuntu/nova.html
}

function main() {
    :
    #use_local_apt_server
    #each_node_must_resolve_the_other_nodes_by_name_in_addition_to_IP_address
    #install_python
    #install_ntp
    #install_sqldb
    #install_mq
    #install_memcached
    #install_keystone
    #install_glance
    #install_neutron
    #install_nova
}
main
