#!/bin/bash

# ifconfig enp0s10 up

FLAT_NETWORK_NAME=external

# Create the provider network
PROVIDER_NETWORK_NAME=provider
openstack network create  --share --external --provider-physical-network $FLAT_NETWORK_NAME --provider-network-type flat $PROVIDER_NETWORK_NAME

# Create the provider subnet
openstack subnet create --network $PROVIDER_NETWORK_NAME --allocation-pool start=10.0.3.230,end=10.0.3.250 --dns-nameserver 8.8.8.8 --gateway 10.0.3.1 --subnet-range 10.0.3.0/24 --no-dhcp $PROVIDER_NETWORK_NAME

# Create a router
ROUTER_NAME=router
openstack router create $ROUTER_NAME
neutron router-gateway-set $ROUTER_NAME $PROVIDER_NETWORK_NAME

# Ping this router
ping -c 1 $( neutron router-port-list -c fixed_ips -f json $ROUTER_NAME | jq -r '.[0].fixed_ips' | jq -r '.ip_address' )

# Create a self-service network
SELFSERVICE_NETWORK_NAME=selfservice
openstack network create $SELFSERVICE_NETWORK_NAME

# Create the self-service subnet
openstack subnet create --network $SELFSERVICE_NETWORK_NAME --dns-nameserver 8.8.8.8 --gateway 10.10.10.1 --subnet-range 10.10.10.0/24 $SELFSERVICE_NETWORK_NAME
neutron router-interface-add $ROUTER_NAME $SELFSERVICE_NETWORK_NAME

# Ping this router again
ping -c 1 10.10.10.1

# Create a flavor
openstack flavor create --id 0 --vcpus 1 --ram 64 --disk 1 m1.nano

# Permit ICMP (ping) in default security group
openstack security group rule create --proto icmp default

# Permit secure shell (SSH) access in default security group
openstack security group rule create --proto tcp --dst-port 22 default

# Launch an instance
SELFSERVICE_INSTANCE_NAME=selfservice-instance
openstack server create --flavor m1.nano --image cirros --nic net-id=$SELFSERVICE_NETWORK_NAME --security-group default $SELFSERVICE_INSTANCE_NAME
openstack server show $SELFSERVICE_INSTANCE_NAME

# Ping this instance
ping -c 1 $( openstack server show -c addresses -f json $SELFSERVICE_INSTANCE_NAME | jq -r '.addresses' | awk -F = '{print $2}' )

# Create a floating IP
openstack floating ip create $PROVIDER_NETWORK_NAME
openstack server add floating ip $SELFSERVICE_INSTANCE_NAME $( openstack floating ip list -c "Floating IP Address" -f json | jq -r '.[0]["Floating IP Address"]' )

# Ping this instance again
ping -c 1 $( openstack floating ip list -c "Floating IP Address" -f json | jq -r '.[0]["Floating IP Address"]' )

# Access this instance remotely
ssh -P cubswin:) cirros@$( openstack floating ip list -c "Floating IP Address" -f json | jq -r '.[0]["Floating IP Address"]' )

#############################

# Create the external network
# See https://kairen.gitbooks.io/openstack-ubuntu-newton/content/ubuntu-binary/neutron/create-network.html
neutron net-create ext-net --router:external --provider:physical_network $PROVIDER_NETWORK_NAME --provider:network_type flat
# See https://docs.openstack.org/newton/install-guide-ubuntu/launch-instance-networks-provider.html#launch-instance-networks-provider
openstack network create  --share --external --provider-physical-network $PROVIDER_NETWORK_NAME --provider-network-type flat provider

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
    # will add a new port to OVS Bridge br-int, e.g., Port "qg-7b98d77a-e4"
    # `ip netns` should see 1 qrouter-xxxx
    # `neutron router-port-list demo-router` should see 1 entry, e.g., "ip_address": "10.0.3.238"
    # `ip netns exec qrouter-6c0b27fa-ad79-4bbc-b66c-1a8b8be6bae7 route -n`
    # `ip netns exec qrouter-6c0b27fa-ad79-4bbc-b66c-1a8b8be6bae7 ip a`
    # `ip netns exec qrouter-6c0b27fa-ad79-4bbc-b66c-1a8b8be6bae7 ping -c 1 10.0.3.238`
    # `ip netns exec qrouter-6c0b27fa-ad79-4bbc-b66c-1a8b8be6bae7 ping -c 1 10.0.3.1`
    # `ip netns exec qrouter-6c0b27fa-ad79-4bbc-b66c-1a8b8be6bae7 ping -c 1 10.0.3.254`
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
