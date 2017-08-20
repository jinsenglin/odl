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

function install_nova() {
    NOVA_COMPUTE_VERSION=2:14.0.7-0ubuntu2~cloud0
    [ "$APT_UPDATED" == "true" ] || apt-get update && APT_UPDATED=true
    apt-get install -y nova-compute=$NOVA_COMPUTE_VERSION

    # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

    # Edit the /etc/nova/nova.conf file, [DEFAULT] section
    sed -i "/^\[DEFAULT\]$/ a transport_url = rabbit://openstack:RABBIT_PASS@os-controller" /etc/nova/nova.conf
    sed -i "/^\[DEFAULT\]$/ a auth_strategy = keystone" /etc/nova/nova.conf
    sed -i "/^\[DEFAULT\]$/ a my_ip = $ENV_MGMT_OS_COMPUTE_IP" /etc/nova/nova.conf
    sed -i "/^\[DEFAULT\]$/ a use_neutron = True" /etc/nova/nova.conf
    sed -i "/^\[DEFAULT\]$/ a firewall_driver = nova.virt.firewall.NoopFirewallDriver" /etc/nova/nova.conf

    # Edit the /etc/nova/nova.conf file, [keystone_authtoken] section
    cat >> /etc/nova/nova.conf <<DATA

[keystone_authtoken]
auth_uri = http://os-controller:5000
auth_url = http://os-controller:35357
memcached_servers = os-controller:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = nova
password = NOVA_PASS
DATA

    # Edit the /etc/nova/nova.conf file, [vnc] section
    cat >> /etc/nova/nova.conf <<DATA

[vnc]
enabled = True
vncserver_listen = 0.0.0.0
vncserver_proxyclient_address = $ENV_MGMT_OS_COMPUTE_IP
novncproxy_base_url = http://os-controller:6080/vnc_auto.html
DATA

    # Edit the /etc/nova/nova.conf file, [glance] section
    cat >> /etc/nova/nova.conf <<DATA

[glance]
api_servers = http://os-controller:9292
DATA

    # Edit the /etc/nova/nova.conf file, [oslo_concurrency] section
    sed -i "/^lock_path=/ d" /etc/nova/nova.conf
    sed -i "/^\[oslo_concurrency\]$/ a lock_path = /var/lib/nova/tmp" /etc/nova/nova.conf

    # Edit the /etc/nova/nova.conf file, [libvirt] section
    sed -i "/^\[libvirt\]$/ a virt_type = qemu" /etc/nova/nova.conf

    # Edit the /etc/nova/nova.conf file, [neutron] section
    # See https://kairen.gitbooks.io/openstack-ubuntu-newton/content/ubuntu-binary/neutron/#compute-node
    cat >> /etc/nova/nova.conf <<DATA

[neutron]
url = http://os-controller:9696
auth_url = http://os-controller:35357
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionOne
project_name = service
username = neutron
password = NEUTRON_PASS
DATA

    # Restart the Compute service
    service nova-compute restart

    # Log files
    # /var/log/nova/nova-compute.log

    # Reference https://docs.openstack.org/newton/install-guide-ubuntu/nova-compute-install.html
}

function install_neutron() {
    NEUTRON_PLUGIN_ML2_VERSION=2:9.4.0-0ubuntu1.1~cloud0
    NEUTRON_OPENVSWITCH_AGENT_VERSION=2:9.4.0-0ubuntu1.1~cloud0
    [ "$APT_UPDATED" == "true" ] || apt-get update && APT_UPDATED=true
    apt install -y neutron-plugin-ml2=$NEUTRON_PLUGIN_ML2_VERSION \
                   neutron-openvswitch-agent=$NEUTRON_OPENVSWITCH_AGENT_VERSION

    # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

    # Edit the /etc/sysctl.conf
    # not mentioned in https://docs.openstack.org/newton/install-guide-ubuntu/neutron-compute-install-option2.html
    # mentioned in https://kairen.gitbooks.io/openstack-ubuntu-newton/content/ubuntu-binary/neutron/#compute-node
    # TODO

    # Edit the /etc/neutron/neutron.conf file, [database] section
    # TODO

    # Edit the /etc/neutron/neutron.conf file, [DEFAULT] section
    # TODO

    # Edit the /etc/neutron/neutron.conf file, [keystone_authtoken] section
    # TODO

    # Edit the /etc/neutron/neutron.conf file, [oslo_messaging_rabbit] section
    # not mentioned in https://docs.openstack.org/newton/install-guide-ubuntu/neutron-compute-install-option2.html
    # mentioned in https://kairen.gitbooks.io/openstack-ubuntu-newton/content/ubuntu-binary/neutron/#compute-node
    # TODO

    # Edit the /etc/neutron/plugins/ml2/openvswitch_agent.ini file, [ovs] section
    # TODO

    # Edit the /etc/neutron/plugins/ml2/openvswitch_agent.ini file, [agent] section
    # TODO

    # Edit the /etc/neutron/plugins/ml2/openvswitch_agent.ini file, [securitygroup] section
    # TODO

    # Restart the Networking services
    service openvswitch-switch restart
    service neutron-openvswitch-agent restart

    # Log files
    # TODO

    # References
    # https://docs.openstack.org/newton/install-guide-ubuntu/neutron-compute-install.html
    # https://docs.openstack.org/newton/install-guide-ubuntu/neutron-compute-install-option2.html
    # https://kairen.gitbooks.io/openstack-ubuntu-newton/content/ubuntu-binary/neutron/#compute-node
    # https://www.centos.bz/2012/04/linux-sysctl-conf/
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
