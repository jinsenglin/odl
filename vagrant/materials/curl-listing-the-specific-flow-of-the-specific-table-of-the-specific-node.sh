#!/bin/bash

CONTROLLER=192.168.34.101
NODE_ID=192356055215691
TABLE_ID=0
FLOW_ID=L2switch-0

curl -H "Accept: application/json" --user admin:admin http://$CONTROLLER:8181/restconf/operational/opendaylight-inventory:nodes/node/openflow:$NODE_ID | jq ".node[0][\"flow-node-inventory:table\"][] | select(.id == $TABLE_ID) | .flow[] | select(.id == \"$FLOW_ID\")"

# Reference https://wiki.opendaylight.org/view/OpenDaylight_OpenFlow_Plugin::End_to_End_Inventory
