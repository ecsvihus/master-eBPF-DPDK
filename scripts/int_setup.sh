#!/bin/bash

if [ "$EUID" -ne 0 ]
	then echo "Please run as root"
	exit
fi

ip netns add server
ip netns add client

ip link set netns server eno1
ip link set netns client eno2

ip netns exec server ip link set up dev eno1
ip netns exec client ip link set up dev eno2

ip netns exec server ip a add 10.0.0.1/24 dev eno1
ip netns exec client ip a add 10.0.0.2/24 dev eno2

#ip netns exec server ip route add 10.0.0.0/24 dev eno1
#ip netns exec client ip route add 10.0.0.0/24 dev eno2

ip netns exec server ip link set up lo
ip netns exec client ip link set up lo
