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

    rm -rf /var/lib/apt/lists/*
    echo 'APT::Get::AllowUnauthenticated "true";' > /etc/apt/apt.conf.d/99-use-local-apt-server
    apt-get update && APT_UPDATED=true
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
    CHRONY_VERSION=2.1.1-1
    [ "$APT_UPDATED" == "true" ] || apt-get update && APT_UPDATED=true
    apt-get install -y chrony=$CHRONY_VERSION

    # TODO
    # Edit the /etc/chrony/chrony.conf file
    # Restart the NTP service

    # Reference https://docs.openstack.org/newton/install-guide-ubuntu/environment-ntp-other.html
}

function install_nova() {
    NOVA_COMPUTE_VERSION=2:14.0.7-0ubuntu2~cloud0
    [ "$APT_UPDATED" == "true" ] || apt-get update && APT_UPDATED=true
    apt-get install -y nova-api=$NOVA_COMPUTE_VERSION

    # TODO
    # ?

    # Reference https://docs.openstack.org/newton/install-guide-ubuntu/nova-compute-install.html
}

function install_neutron() {
    NEUTRON_PLUGIN_ML2_VERSION=2:9.4.0-0ubuntu1.1~cloud0
    NEUTRON_OPENVSWITCH_AGENT_VERSION=2:9.4.0-0ubuntu1.1~cloud0
    [ "$APT_UPDATED" == "true" ] || apt-get update && APT_UPDATED=true
    apt install -y neutron-plugin-ml2=$NEUTRON_PLUGIN_ML2_VERSION \
                   neutron-openvswitch-agent=$NEUTRON_OPENVSWITCH_AGENT_VERSION

    # TODO
    # ?

    # Reference https://docs.openstack.org/newton/install-guide-ubuntu/neutron-controller-install-option2.html
    # This reference uses neutron-linuxbridge-agent, but we need neutron-openvswitch-agent.
    # This reference is for 2-nodes deployment (one controller, one compute), but we need 3-nodes deployment (one controller, one network, one compute).

    # Reference https://docs.openstack.org/neutron/pike/admin/deploy-ovs-selfservice.html
    # This reference is for pike version, but we need newton version.
    # This reference uses neutron-openvswitch-agent.
    # This reference is for VXLAN self-service networks.
    # This reference is for 3-nodes deployment.

    # Reference http://www.unixarena.com/2015/10/openstack-configure-network-service-neutron-controller-part-6.html
    # Reference http://www.unixarena.com/2015/10/openstack-configure-neutron-on-network-node-part-7.html
    # Reference http://www.unixarena.com/2015/10/openstack-configure-neutron-on-compute-node-part-8.html
    # This reference is for 3-nodes deployment.
    # `apt-get install neutron-server neutron-plugin-ml2` # for controller node
    # `apt-get install neutron-plugin-ml2 neutron-plugin-openvswitch-agent neutron-l3-agent neutron-dhcp-agent neutron-metadata-agent` # for network node
    # `apt-get install neutron-plugin-ml2 neutron-plugin-openvswitch-agent` # for compute node

}


function main() {
    :
    use_local_apt_server
    each_node_must_resolve_the_other_nodes_by_name_in_addition_to_IP_address
    install_python
    install_ntp
    install_nova
    install_neutron
}
main
