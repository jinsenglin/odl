#!/bin/bash

# 1-0
# TODO rename enp0s10 to 12345678-1234-1234-1234-123456789012 

# 1-2
systemctl stop neutron-l3-agent
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
ovs-vsctl set Open_vSwitch . other_config:local_ip=10.0.1.21
ovs-vsctl show
ovs-vsctl get Open_vSwitch . other_config

# 1-6
apt-get install -y python-networking-odl=1:2.0.1~git20160926.416a5c7-0ubuntu1~cloud0

# 1-7
sed -i "/^mechanism_drivers = / d" /etc/neutron/plugins/ml2/ml2_conf.ini
sed -i "/^\[ml2\]$/ a mechanism_drivers = opendaylight" /etc/neutron/plugins/ml2/ml2_conf.ini

# 1-8
cat >> /etc/neutron/plugins/ml2/ml2_conf.ini <<DATA

[ml2_odl]
url = http://odl-controller:8080/controller/nb/v2/neutron
password = admin
username = admin
DATA

# 1-9
sed -i "/^service_plugins = / d" /etc/neutron/neutron.conf
sed -i "/^\[DEFAULT\]$/ a service_plugins = odl-router" /etc/neutron/neutron.conf

# 1-10
sed -i "/^\[DEFAULT\]$/ a force_metadata = True" /etc/neutron/dhcp_agent.ini

# 1-11
cat >> /etc/neutron/dhcp_agent.ini <<DATA

[OVS]
ovsdb_interface = vsctl
DATA

# 1-15
ovs-vsctl set Open_vSwitch . other_config:provider_mappings=external:enp0s10
ovs-vsctl show
ovs-vsctl get Open_vSwitch . other_config

<<LOG
2017-08-23 07:36:40,359 | INFO  | pool-39-thread-1 | InterfaceStateChangeListener     | 346 - org.opendaylight.netvirt.vpnmanager-impl - 0.3.3.Boron-SR3 | Received interface Interface{getAdminStatus=Up, getLowerLayerIf=[openflow:172541724857349:1], getName=172541724857349:enp0s10, getOperStatus=Up, getPhysAddress=PhysAddress [_value=08:00:27:a8:e7:fa], augmentations={}} add event
2017-08-23 07:36:40,361 | ERROR | pool-39-thread-1 | QosInterfaceStateChangeListener  | 350 - org.opendaylight.netvirt.neutronvpn-impl - 0.3.3.Boron-SR3 | Qos:Exception caught in Interface Operational State Up event
java.lang.IllegalArgumentException: Supplied value "172541724857349:enp0s10" does not match required pattern "^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$"
        at com.google.common.base.Preconditions.checkArgument(Preconditions.java:145)[65:com.google.guava:18.0.0]
        at org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.Uuid.<init>(Uuid.java:55)[80:org.opendaylight.mdsal.model.ietf-yang-types-20130715:2013.7.15.9_3-Boron-SR3]
        at org.opendaylight.netvirt.neutronvpn.QosInterfaceStateChangeListener.add(QosInterfaceStateChangeListener.java:61)[350:org.opendaylight.netvirt.neutronvpn-impl:0.3.3.Boron-SR3]
        at org.opendaylight.netvirt.neutronvpn.QosInterfaceStateChangeListener.add(QosInterfaceStateChangeListener.java:27)[350:org.opendaylight.netvirt.neutronvpn-impl:0.3.3.Boron-SR3]
        at org.opendaylight.genius.datastoreutils.AsyncDataTreeChangeListenerBase$DataTreeChangeHandler.run(AsyncDataTreeChangeListenerBase.java:136)[310:org.opendaylight.genius.mdsalutil-api:0.1.3.Boron-SR3]
        at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1149)[:1.8.0_131]
        at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:624)[:1.8.0_131]
        at java.lang.Thread.run(Thread.java:748)[:1.8.0_131]
2017-08-23 07:36:40,363 | ERROR | pool-39-thread-1 | TransportZoneNotificationUtil    | 350 - org.opendaylight.netvirt.neutronvpn-impl - 0.3.3.Boron-SR3 | No interfaces in configuration
2017-08-23 07:36:40,378 | INFO  | nPool-1-worker-1 | NatInterfaceStateChangeListener  | 355 - org.opendaylight.netvirt.natservice-impl - 0.3.3.Boron-SR3 | NAT Service : Unable to process add for interface 172541724857349:enp0s10
2017-08-23 07:45:13,817 | WARN  | ssionScavenger-3 | teInvalidatingHashSessionManager | 219 - org.ops4j.pax.web.pax-web-jetty - 3.2.9 | Timing out for 1 session(s) with id 1skpua0ncoa5xena8s7p9jdvp
LOG
