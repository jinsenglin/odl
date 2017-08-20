#!/bin/bash

set -e

ENV_MGMT_NETWORK="10.0.0.0/24"
ENV_MGMT_OS_CONTROLLER_IP="10.0.0.11"
ENV_MGMT_OS_NETWORK_IP="10.0.0.21"
ENV_MGMT_OS_COMPUTE_IP="10.0.0.31"
ENV_MGMT_ODL_CONTROLLER_IP="10.0.0.41"

LOG=/tmp/provision.log
date | tee $LOG            # when:  Thu Aug 10 07:48:13 UTC 2017
whoami | tee -a $LOG       # who:   root
pwd | tee -a $LOG          # where: /home/vagrant

CACHE=/vagrant/cache
[ -d $CACHE ] || mkdir -p $CACHE 

function use_public_apt_server() {
    apt install -y software-properties-common
    add-apt-repository cloud-archive:newton
    apt-get update && APT_UPDATED=true

    # Reference https://docs.openstack.org/newton/install-guide-ubuntu/environment-packages.html
}

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
$ENV_MGMT_OS_CONTROLLER_IP os-controller
$ENV_MGMT_OS_NETWORK_IP os-network
$ENV_MGMT_OS_COMPUTE_IP os-compute
$ENV_MGMT_ODL_CONTROLLER_IP odl-controller
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

    # # # # # # # # # # # # # # # # ## # # # # # # # # # # # # # # # # # # # # # # # # ## # # # # # # # #

    # To connect to the os-controller node
    sed -i "s/^pool /#pool /g" /etc/chrony/chrony.conf
    sed -i "s/^server /#server /g" /etc/chrony/chrony.conf
    echo "server os-controller iburst" >> /etc/chrony/chrony.conf

    # Restart the NTP service
    service chrony restart

    # Verify operation
    chronyc sources

    # Log files
    # /var/log/chrony/measurements.log
    # /var/log/chrony/statistics.log
    # /var/log/chrony/tracking.log

    # Reference https://docs.openstack.org/newton/install-guide-ubuntu/environment-ntp-other.html
}

function install_neutron() {
    NEUTRON_PLUGIN_ML2_VERSION=2:9.4.0-0ubuntu1.1~cloud0
    NEUTRON_OPENVSWITCH_AGENT_VERSION=2:9.4.0-0ubuntu1.1~cloud0
    NEUTRON_L3_AGENT_VERSION=2:9.4.0-0ubuntu1.1~cloud0
    NEUTRON_DHCP_AGENT_VERSION=2:9.4.0-0ubuntu1.1~cloud0
    NEUTRON_METADATA_AGENT_VERSION=2:9.4.0-0ubuntu1.1~cloud0
    [ "$APT_UPDATED" == "true" ] || apt-get update && APT_UPDATED=true
    apt install -y neutron-plugin-ml2=$NEUTRON_PLUGIN_ML2_VERSION \
                   neutron-openvswitch-agent=$NEUTRON_OPENVSWITCH_AGENT_VERSION \
                   neutron-l3-agent=$NEUTRON_L3_AGENT_VERSION \
                   neutron-dhcp-agent=$NEUTRON_DHCP_AGENT_VERSION \
                   neutron-metadata-agent=$NEUTRON_METADATA_AGENT_VERSION

    # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

    # Edit the /etc/neutron/neutron.conf file, [database] section
    # TODO

    # Edit the /etc/neutron/neutron.conf file, [DEFAULT] section
    # TODO

    # Edit the /etc/neutron/neutron.conf file, [keystone_authtoken] section
    # TODO

    # Edit the /etc/neutron/neutron.conf file, [nova] section
    # TODO

    # Edit the /etc/neutron/plugins/ml2/ml2_conf.ini file, [ml2] section
    # TODO

    # Edit the /etc/neutron/plugins/ml2/ml2_conf.ini file, [ml2_type_flat] section
    # TODO

    # Edit the /etc/neutron/plugins/ml2/ml2_conf.ini file, [ml2_type_vxlan] section
    # TODO

    # Edit the /etc/neutron/plugins/ml2/ml2_conf.ini file, [securitygroup] section
    # TODO

    # Edit the /etc/neutron/plugins/ml2/linuxbridge_agent.ini file, [linux_bridge] section
    # TODO

    # Edit the /etc/neutron/plugins/ml2/linuxbridge_agent.ini file, [vxlan] section
    # TODO

    # Edit the /etc/neutron/plugins/ml2/linuxbridge_agent.ini file, [securitygroup] section
    # TODO

    # Edit the /etc/neutron/l3_agent.ini file, [DEFAULT] section
    # TODO

    # Edit the /etc/neutron/dhcp_agent.ini file, [DEFAULT] section
    # TODO

    # Edit the /etc/neutron/metadata_agent.ini file, [DEFAULT] section
    # TODO

    # Edit the /etc/nova/nova.conf file, [neutron] section
    # TODO

    # Restart the Networking services
    service openvswitch-switch restart
    service neutron-openvswitch-agent restart
    service neutron-dhcp-agent restart
    service neutron-metadata-agent restart
    service neutron-l3-agent restart

    # Verify operation
    #source /root/admin-openrc
    #openstack neutron ext-list
    #openstack network agent list

    # Log files
    # TODO

    # References
    # Reference https://docs.openstack.org/newton/install-guide-ubuntu/neutron-controller-install.html
    # Reference https://docs.openstack.org/newton/install-guide-ubuntu/neutron-controller-install-option2.html
    # https://kairen.gitbooks.io/openstack-ubuntu-newton/content/ubuntu-binary/neutron/#network-node
}

function main() {
    :
    use_local_apt_server
    each_node_must_resolve_the_other_nodes_by_name_in_addition_to_IP_address
    install_python
    install_ntp
    install_neutron
}
main
