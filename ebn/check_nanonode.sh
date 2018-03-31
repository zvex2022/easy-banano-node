#!/bin/bash
response=$(curl --connect-timeout 3 --max-time 5 -g -d '{ "action": "version" }' [::1]:7076);
if [ $? -ne 0 ]; then
    docker restart ebn_bananonode_1
fi;