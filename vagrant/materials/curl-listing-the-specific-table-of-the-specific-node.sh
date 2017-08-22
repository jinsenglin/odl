#!/bin/bash

CONTROLLER=192.168.34.101
NODE_ID=192356055215691
TABLE_ID=0

curl -H "Accept: application/json" --user admin:admin http://$CONTROLLER:8181/restconf/operational/opendaylight-inventory:nodes/node/openflow:$NODE_ID | jq ".node[0][\"flow-node-inventory:table\"][] | select(.id == $TABLE_ID)"
# Against `ovs-ofctl dump-tables br0`

# Reference https://wiki.opendaylight.org/view/OpenDaylight_OpenFlow_Plugin::End_to_End_Inventory

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# Another method

curl -H "Accept: application/json" --user admin:admin http://$CONTROLLER:8181/restconf/operational/opendaylight-inventory:nodes/node/openflow:$NODE_ID/table/$TABLE_ID/

# Reference https://wiki.opendaylight.org/view/OpenDaylight_OpenFlow_Plugin:End_to_End_Flows#Check_for_your_flow_in_the_controller_config_via_RESTCONF
# Reference https://wiki.opendaylight.org/view/OpenDaylight_OpenFlow_Plugin:End_to_End_Flows#Look_for_your_flow_stats_in_the_controller_operational_data_via_RESTCONF
