#!/bin/bash

CONTROLLER=192.168.34.101
NODE_ID=192356055215691
TABLE_ID=0
FLOW_ID=L2switch-0

curl -H "Accept: application/json" --user admin:admin http://$CONTROLLER:8181/restconf/operational/opendaylight-inventory:nodes/node/openflow:$NODE_ID | jq ".node[0][\"flow-node-inventory:table\"][] | select(.id == $TABLE_ID) | .flow[] | select(.id == \"$FLOW_ID\")"
# Against `ovs-ofctl dump-flows br0`

# Reference https://wiki.opendaylight.org/view/OpenDaylight_OpenFlow_Plugin::End_to_End_Inventory

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# Another method

curl -H "Accept: application/json" --user admin:admin http://$CONTROLLER:8181/restconf/operational/opendaylight-inventory:nodes/node/openflow:$NODE_ID/table/$TABLE_ID/flow/$FLOW_ID | jq '.'

# Reference http://www.brocade.com/content/html/en/user-guide/SDN-Controller-2.1.0-User-Guide/GUID-D1E545F1-EF0B-4457-8BE7-C9413684072B.html
