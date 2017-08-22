#!/bin/bash

CONTROLLER=192.168.34.101
NODE_ID=192356055215691
TABLE_ID=0
FLOW_ID=1

curl -X DELETE -H "Content-Type: application/xml" -H "Accept: application/json" --user admin:admin http://$CONTROLLER:8181/restconf/config/opendaylight-inventory:nodes/node/openflow:$NODE_ID/table/$TABLE_ID/flow/$FLOW_ID

# Reference http://www.brocade.com/content/html/en/user-guide/SDN-Controller-2.1.0-User-Guide/GUID-6AF8868F-F53A-48A3-BDAD-412A6F66E8BA.html

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# Another method (same)

# Reference https://community.extremenetworks.com/extreme/topics/how-do-i-add-delete-modify-a-flow-using-the-odl-api-or-curl

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# Another method (different)

# Reference https://wiki.opendaylight.org/view/OpenDaylight_OpenFlow_Plugin:End_to_End_Flows#Removing_flow_via_rpc
