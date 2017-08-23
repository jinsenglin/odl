#!/bin/bash

# 1-0 rename enp0s10 to 12345678-1234-1234-1234-123456789012
# Modify the file /etc/udev/rules.d/70-persistent-net.rules
# SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="08:00:27:a8:e7:fa", NAME="12345678-1234-1234-1234-123456789012"
# Reboot
# ifconfig 12345678-1234-1234-1234-123456789012 up
#
# OR try use 'odl-router_v2' instead of 'odl-router' (skipped)

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
# ovs-vsctl set Open_vSwitch . other_config:provider_mappings=external:enp0s10
ovs-vsctl set Open_vSwitch . other_config:provider_mappings=external:12345678-1234-1234-1234-123456789012
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


######## ######## ######## ######## ######## ######## ######## ######## ######## ########


2017-08-23 09:58:37,154 | INFO  | nPool-1-worker-1 | NeutronPortChangeListener        | 350 - org.opendaylight.netvirt.neutronvpn-impl - 0.3.3.Boron-SR3 | Of-port-interface creation for port 78f58783-71e1-4977-a84f-db33d3a65cd1
2017-08-23 09:58:37,179 | INFO  | pool-16-thread-1 | VpnSubnetRouteHandler            | 346 - org.opendaylight.netvirt.vpnmanager-impl - 0.3.3.Boron-SR3 | onPortAddedToSubnet: Port 78f58783-71e1-4977-a84f-db33d3a65cd1 being added to subnet cf6ac4be-36bd-475a-bab7-4169e5e8e6b9
2017-08-23 09:58:37,186 | INFO  | pool-16-thread-1 | LockManager                      | 331 - org.opendaylight.genius.lockmanager-impl - 0.1.3.Boron-SR3 | Locking cf6ac4be-36bd-475a-bab7-4169e5e8e6b9
2017-08-23 09:58:37,188 | ERROR | pool-39-thread-1 | NatUtil                          | 355 - org.opendaylight.netvirt.natservice-impl - 0.3.3.Boron-SR3 | No resolution was found to GW ip IpAddress [_ipv4Address=Ipv4Address [_value=10.0.3.1]] in subnet cf6ac4be-36bd-475a-bab7-4169e5e8e6b9
2017-08-23 09:58:37,188 | INFO  | pool-39-thread-1 | LockManager                      | 331 - org.opendaylight.genius.lockmanager-impl - 0.1.3.Boron-SR3 | Locking snatGroupIdPoolsnatmiss.cf6ac4be-36bd-475a-bab7-4169e5e8e6b9
2017-08-23 09:58:37,192 | INFO  | pool-16-thread-1 | LockManager                      | 331 - org.opendaylight.genius.lockmanager-impl - 0.1.3.Boron-SR3 | Acquired lock cf6ac4be-36bd-475a-bab7-4169e5e8e6b9
2017-08-23 09:58:37,193 | INFO  | pool-39-thread-1 | LockManager                      | 331 - org.opendaylight.genius.lockmanager-impl - 0.1.3.Boron-SR3 | Acquired lock snatGroupIdPoolsnatmiss.cf6ac4be-36bd-475a-bab7-4169e5e8e6b9
2017-08-23 09:58:37,194 | INFO  | pool-39-thread-1 | LockManager                      | 331 - org.opendaylight.genius.lockmanager-impl - 0.1.3.Boron-SR3 | Unlocking snatGroupIdPoolsnatmiss.cf6ac4be-36bd-475a-bab7-4169e5e8e6b9
2017-08-23 09:58:37,195 | WARN  | nPool-1-worker-1 | InterfaceConfigListener          | 337 - org.opendaylight.genius.interfacemanager-impl - 0.1.3.Boron-SR3 | parent refs not specified for 78f58783-71e1-4977-a84f-db33d3a65cd1
2017-08-23 09:58:37,196 | INFO  | pool-39-thread-1 | ExternalNetworkGroupInstaller    | 355 - org.opendaylight.netvirt.natservice-impl - 0.3.3.Boron-SR3 | Installing ext-net group 200000 entry for subnet cf6ac4be-36bd-475a-bab7-4169e5e8e6b9 with macAddress null (extInterfaces: [105953614791086:12345678-1234-1234-1234-123456789012:flat])
2017-08-23 09:58:37,197 | ERROR | pool-39-thread-1 | InterfaceManagerRpcService       | 337 - org.opendaylight.genius.interfacemanager-impl - 0.1.3.Boron-SR3 | Retrieval of datapath id for the key {105953614791086:12345678-1234-1234-1234-123456789012:flat} failed due to missing Interface-state
2017-08-23 09:58:37,197 | ERROR | pool-39-thread-1 | NatUtil                          | 355 - org.opendaylight.netvirt.natservice-impl - 0.3.3.Boron-SR3 | NAT Service : Could not retrieve DPN Id for interface 105953614791086:12345678-1234-1234-1234-123456789012:flat
2017-08-23 09:58:37,197 | WARN  | pool-39-thread-1 | ExternalNetworkGroupInstaller    | 355 - org.opendaylight.netvirt.natservice-impl - 0.3.3.Boron-SR3 | No DPN for interface 105953614791086:12345678-1234-1234-1234-123456789012:flat. NAT ext-net flow will not be installed
2017-08-23 09:58:37,197 | ERROR | pool-39-thread-1 | InterfacemgrProvider             | 337 - org.opendaylight.genius.interfacemanager-impl - 0.1.3.Boron-SR3 | Interface 78f58783-71e1-4977-a84f-db33d3a65cd1 is not present
2017-08-23 09:58:37,197 | WARN  | pool-39-thread-1 | ElanInterfaceManager             | 354 - org.opendaylight.netvirt.elanmanager-impl - 0.3.3.Boron-SR3 | Interface 78f58783-71e1-4977-a84f-db33d3a65cd1 is removed from Interface Oper DS due to port down 
2017-08-23 09:58:37,207 | INFO  | pool-16-thread-1 | VpnSubnetRouteHandler            | 346 - org.opendaylight.netvirt.vpnmanager-impl - 0.3.3.Boron-SR3 | onPortAddedToSubnet: Port 78f58783-71e1-4977-a84f-db33d3a65cd1 is part of a subnet cf6ac4be-36bd-475a-bab7-4169e5e8e6b9 that is not in VPN, ignoring
2017-08-23 09:58:37,209 | INFO  | pool-16-thread-1 | LockManager                      | 331 - org.opendaylight.genius.lockmanager-impl - 0.1.3.Boron-SR3 | Unlocking cf6ac4be-36bd-475a-bab7-4169e5e8e6b9
2017-08-23 09:58:37,449 | INFO  | pool-39-thread-1 | ExternalRoutersListener          | 355 - org.opendaylight.netvirt.natservice-impl - 0.3.3.Boron-SR3 | NAT Service : Add external router event for b3f5d0ce-d1b1-4933-8675-ae7a56c89680
2017-08-23 09:58:37,460 | INFO  | pool-39-thread-1 | ExternalRoutersListener          | 355 - org.opendaylight.netvirt.natservice-impl - 0.3.3.Boron-SR3 | NAT Service : Installing NAT default route on all dpns part of router b3f5d0ce-d1b1-4933-8675-ae7a56c89680
2017-08-23 09:58:37,461 | INFO  | pool-39-thread-1 | NAPTSwitchSelector               | 355 - org.opendaylight.netvirt.natservice-impl - 0.3.3.Boron-SR3 | NAT Service : Select a new NAPT switch for router b3f5d0ce-d1b1-4933-8675-ae7a56c89680
2017-08-23 09:58:37,461 | INFO  | pool-39-thread-1 | NAPTSwitchSelector               | 355 - org.opendaylight.netvirt.natservice-impl - 0.3.3.Boron-SR3 | NAT Service : Delaying NAPT switch selection due to no dpns scenario for router b3f5d0ce-d1b1-4933-8675-ae7a56c89680
2017-08-23 09:58:37,461 | INFO  | pool-39-thread-1 | ExternalRoutersListener          | 355 - org.opendaylight.netvirt.natservice-impl - 0.3.3.Boron-SR3 | NAT Service : Unable to to select the primary NAPT switch for router b3f5d0ce-d1b1-4933-8675-ae7a56c89680
2017-08-23 09:58:37,461 | INFO  | pool-39-thread-1 | ExternalRoutersListener          | 355 - org.opendaylight.netvirt.natservice-impl - 0.3.3.Boron-SR3 | NAT Service: Failed to get or allocate NAPT switch for router b3f5d0ce-d1b1-4933-8675-ae7a56c89680. NAPT flow installation will be delayed
LOG
