#!/bin/bash

CONTROLLER=192.168.34.101

curl -H "Accept: application/json" --user admin:admin http://$CONTROLLER:8181/restconf/operational/opendaylight-inventory:nodes/ | jq '.'

# Reference https://wiki.opendaylight.org/view/OpenDaylight_OpenFlow_Plugin::End_to_End_Inventory
