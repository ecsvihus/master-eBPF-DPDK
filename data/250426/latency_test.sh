#!/bin/bash

if [ "$EUID" -ne 0 ]
	then echo "Please run as root"
	exit
fi

count=100


test () {
	iperfPID=""
	tcpdumpPID=""
	if [ $2 -ge 1 ]; then
		ip netns exec client iperf3 -c 10.0.0.1 -t 86400 -b $2M -M512 &> ./log &
		iperfPID=$!
		sleep 0.5
		sudo ip netns exec client sudo tcpdump -ni eno2 icmp -w $1-$2M.pcap &
		tcpdumpPID=$!
		sleep 0.5
	fi

	printf "iperfPID="$iperfPID\
		"\ntcpdumpPID="$tcpdumpPID"\n"

	sudo ip netns exec client sudo python3 \ 
		~/2024-cnsm-5g-code/scripts/trafgen/5g-dp-client-v3.py \
		icmp det -1 small $count 10.0.0.1 6789 1

	sudo ip netns exec client ping -c $count 10.0.0.1 -i 0 | 
		awk '{ print $7 }' |
		tail -n +2 | head -n -4 |
		cut -c 6- > $1-$2M.dat
	
	if [ $2 -ge 1 ]; then
		kill $iperfPID
		kill $tcpdumpPID
	fi
}

DuTs=(
	dpdk
	napi
	xdp
)
for dut in "${DuTs[@]}"; do
	read -p "Change DuT to $dut, and then press enter: "
	for i in {0..10000..100}; do
		echo "running $dut at "$i"M"
		test $dut $i
	done
done
