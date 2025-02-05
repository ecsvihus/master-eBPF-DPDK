#!/bin/bash

if [ -z "${1}" ]; then
	echo "bad )::"
	exit 1
fi

if ! sudo ip netns exec $1 ip a &> /dev/null; then
	echo "couldn't find veth interface"
fi

#ip=$(sudo ip netns exec test2 ip a | grep "global $1" | awk '{print $2}')



#sudo ip route del $ip
sudo ip netns delete $1
