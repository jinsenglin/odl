#!/bin/bash

# 1-2
systemctl stop neutron-openvswitch-agent
systemctl stop openvswitch-switch

# 1-3
rm -rf /var/log/openvswitch/*
rm -rf /etc/openvswitch/conf.db
systemctl start openvswitch-switch
ovs-vsctl show

# 1-4
ovs-vsctl set-manager tcp:10.0.0.41:6640
ovs-vsctl show

# 1-5
ovs-vsctl set Open_vSwitch . other_config:local_ip=10.0.1.31
ovs-vsctl show
ovs-vsctl get Open_vSwitch . other_config

# 1-6
apt-get install -y python-networking-odl=1:2.0.1~git20160926.416a5c7-0ubuntu1~cloud0

# 1-9
sed -i "/^service_plugins = / d" /etc/neutron/neutron.conf
sed -i "/^\[DEFAULT\]$/ a service_plugins = odl-router" /etc/neutron/neutron.conf
