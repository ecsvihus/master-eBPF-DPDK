#!/bin/bash

if [ "$EUID" -ne 0 ]
	then echo "Please run as root"
	exit
fi

count=1000000


test () {
	iperfPID=""
	if [ $2 -ge 1 ]; then
		ip netns exec client iperf3 -c 10.0.0.1 -t 86400 -b $2G -M512 &> /dev/null &
		iperfPID=$!
		sleep 1
	fi

	sudo ip netns exec client ping -c $count 10.0.0.1 -i 0 | 
		awk '{ print $7 }' |
		tail -n +2 | head -n -4 |
		cut -c 6- > $1-$2G.dat
	
	if [ $2 -ge 1 ]; then
		kill $iperfPID
	fi
}

DuTs=(
	dpdk
	napi
	xdp
)
for dut in "${DuTs[@]}"; do
	read -p "Change DuT to $dut, and then press enter: "
	for i in {0..6..3}; do
		echo "running $dut at "$i"G"
		test $dut $i
	done
done
