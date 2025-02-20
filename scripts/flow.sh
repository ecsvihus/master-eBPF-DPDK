#!/bin/bash

sudo ovs-ofctl del-flows $1

#sudo ovs-vsctl add-port $1 $2

sudo ovs-ofctl add-flow $1 in_port=$2,actions=output:$3
sudo ovs-ofctl add-flow $1 in_port=$3,actions=output:$2
