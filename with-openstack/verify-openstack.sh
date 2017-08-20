#!/bin/bash

# Create the external network
# See https://kairen.gitbooks.io/openstack-ubuntu-newton/content/ubuntu-binary/neutron/create-network.html
neutron net-create ext-net --router:external --provider:physical_network provider --provider:network_type flat
# See https://docs.openstack.org/newton/install-guide-ubuntu/launch-instance-networks-provider.html#launch-instance-networks-provider
openstack network create  --share --external --provider-physical-network provider --provider-network-type flat provider

# Create the external subnet
# See https://kairen.gitbooks.io/openstack-ubuntu-newton/content/ubuntu-binary/neutron/create-network.html
neutron subnet-create ext-net 10.0.3.0/24 --allocation-pool start=10.0.3.230,end=10.0.3.250 --disable-dhcp --gateway 10.0.3.1 --name ext-subnet
# See https://docs.openstack.org/newton/install-guide-ubuntu/launch-instance-networks-provider.html#launch-instance-networks-provider
openstack subnet create --network provider --allocation-pool start=10.0.3.101,end=10.0.3.250 --dns-nameserver 8.8.4.4 --gateway 10.0.3.1 --subnet-range 10.0.3.0/24 provider
openstack subnet create --network provider --allocation-pool start=203.0.113.101,end=203.0.113.250 --dns-nameserver 8.8.4.4 --gateway 203.0.113.1 --subnet-range 203.0.113.0/24 provider

# Create the self-service network
# See https://kairen.gitbooks.io/openstack-ubuntu-newton/content/ubuntu-binary/neutron/create-network.html
neutron net-create demo-net
# See https://docs.openstack.org/newton/install-guide-ubuntu/launch-instance-networks-selfservice.html
openstack network create selfservice

# Create the self-service subnet
# See https://kairen.gitbooks.io/openstack-ubuntu-newton/content/ubuntu-binary/neutron/create-network.html
neutron subnet-create demo-net 192.168.1.0/24 --gateway 192.168.1.1 --dns-nameserver 8.8.8.8 --name demo-subnet
# See https://docs.openstack.org/newton/install-guide-ubuntu/launch-instance-networks-selfservice.html
openstack subnet create --network selfservice --dns-nameserver 8.8.4.4 --gateway 172.16.1.1 --subnet-range 172.16.1.0/24 selfservice

# Create a router
# See https://kairen.gitbooks.io/openstack-ubuntu-newton/content/ubuntu-binary/neutron/create-network.html
neutron router-create demo-router
neutron router-interface-add demo-router demo-subnet
neutron router-gateway-set demo-router ext-net
# See https://docs.openstack.org/newton/install-guide-ubuntu/launch-instance-networks-selfservice.html
openstack router create router
neutron router-interface-add router selfservice
neutron router-gateway-set router provider

# Verify operation
ping -c 4 10.0.3.232
#
# `ip netns` should see 1 qrouter-xxxx 2 dhcp-xxxx
# `neutron router-port-list router` should see 10.0.3.xxxx
ping -c 4 10.0.3.109
#
# `ip netns` should see 1 qrouter-xxxx 2 dhcp-xxxx
# `neutron router-port-list router` should see 203.0.113.xxxx
ping -c 4 203.0.113.101
 
# Create m1.nano flavor
# Generate a key pair
# Add security group rules
# Launch an instance
# Access the instance remotely

# Reference https://docs.openstack.org/newton/install-guide-ubuntu/launch-instance-networks-provider.html#launch-instance-networks-provider
# Reference https://docs.openstack.org/newton/install-guide-ubuntu/launch-instance-networks-selfservice.html
# Reference https://docs.openstack.org/newton/install-guide-ubuntu/launch-instance.html#launch-instance
# Reference https://docs.openstack.org/newton/install-guide-ubuntu/launch-instance-selfservice.html
