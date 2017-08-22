#!/bin/bash

CONTROLLER=192.168.34.101
NODE_ID=192356055215691

curl -H "Accept: application/xml" --user admin:admin http://$CONTROLLER:8181/restconf/operational/opendaylight-inventory:nodes/node/openflow:$NODE_ID | xmllint --format -

# Reference https://wiki.opendaylight.org/view/OpenDaylight_OpenFlow_Plugin::End_to_End_Inventory
