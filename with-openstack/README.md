# Goal

* type_drivers: flat,vlan,vxlan
* provider network type: flat
* tenant_network_types: vxlan
* mechanism_drivers: openvswitch,l2population

---
# Note

OpenStack version used is this deployment is newton.

---

# Note

Each VirtualBox VM by default has a NIC named "enp0s3"

* VirtualBox network adapter :: Attached to: NAT
* VirtualBox network adapter :: Promiscuous mode: DENY
* IP: 10.0.2.15
* GW: 10.0.2.2
* MASK: 255.255.255.0

In this deployment, we add 4 NICs:

* VirtualBox network adapter :: Attached to: HOST-ONLY
* VirtualBox network adapter :: Promiscuous mode: ALLOW-ALL
* C class network
  * 10.0.0.0/24 for management network
  * 10.0.1.0/24 for tunnel network
  * 10.0.3.0/24 preserved, not yet used
  * 10.0.4.0/24 preserved, not yet used

Question: which one is used to be public network?

