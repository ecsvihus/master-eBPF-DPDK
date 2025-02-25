#!/bin/bash

if [ -z "${2}" ]; then
	echo "Bad Arguments, command usage:"
	echo "veth-setup <name> <last ip octet>"
	echo "example:"
	echo "veth-setup veth 10"
	exit 2
fi

sudo ip netns add $1
sudo ip link add name $1-host type veth peer name $1-client
sudo ip link set $1-client netns $1
sudo ip netns exec $1 ip addr add 192.168.$2.2/24 dev $1-client
sudo ip netns exec $1 ip link set $1-client up
sudo ip netns exec $1 ip link set lo up
sudo ip link set $1-host up
sudo ip route add 192.168.$2.2/32 dev $1-host
sudo ip netns exec $1 ip route add default via 192.168.$2.2 dev $1-client
